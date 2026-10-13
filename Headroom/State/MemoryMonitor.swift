import AppKit
import Observation

/// Owns the numbers on screen. Refreshes system memory every 5 seconds for the menu bar, and the
/// full per-process RAM and CPU breakdown every 2 seconds while the panel is open.
@MainActor
@Observable
final class MemoryMonitor {
  private(set) var systemMemory: SystemMemory?
  private(set) var groups: [MemoryGroup] = []
  private(set) var cpuUsage: HostCPUUsage?
  private(set) var cpuGroups: [CPUGroup] = []
  private(set) var lastUpdated: Date?
  private(set) var busyGroupIds: Set<String> = []
  private(set) var statusMessage: String?

  @ObservationIgnored private let processReader = ProcessReader()
  @ObservationIgnored private let cpuReader = CPUReader()
  @ObservationIgnored private let groupBuilder = GroupBuilder()
  @ObservationIgnored private var visiblePanelCount = 0
  @ObservationIgnored private var isRefreshingGroups = false

  private var isPanelVisible: Bool { visiblePanelCount > 0 }

  init() {
    Task {
      if let title = LaunchOptions.groupTitleToStop {
        return await stopGroupAndExit(titled: title)
      }
      guard !LaunchOptions.printsGroupsAndExits else { return await printGroupsAndExit() }
      await runLoop()
    }
  }

  func panelDidAppear() {
    visiblePanelCount += 1
    systemMemory = SystemMemoryReader.read()
    Task { await refreshGroups() }
  }

  func panelDidDisappear() {
    visiblePanelCount = max(0, visiblePanelCount - 1)
  }

  func perform(_ action: GroupAction, on group: MemoryGroup) {
    guard !busyGroupIds.contains(group.id) else { return }
    busyGroupIds.insert(group.id)
    statusMessage = nil
    Task {
      let message = await GroupActionRunner.run(action, on: group)
      busyGroupIds.remove(group.id)
      statusMessage = message
      systemMemory = SystemMemoryReader.read()
      await refreshGroups()
    }
  }

  private func runLoop() async {
    while !Task.isCancelled {
      systemMemory = SystemMemoryReader.read()
      if isPanelVisible || groups.isEmpty {
        await refreshGroups()
      } else {
        // Keeps a recent CPU reading on hand, so the CPU tab has numbers the moment it opens.
        _ = await cpuReader.sample()
      }
      try? await Task.sleep(for: isPanelVisible ? .seconds(2) : .seconds(5))
    }
  }

  private func printGroupsAndExit() async {
    systemMemory = SystemMemoryReader.read()
    await refreshGroups()
    print(GroupReport.text(memory: systemMemory, groups: groups))
    exit(0)
  }

  private func stopGroupAndExit(titled title: String) async {
    await refreshGroups()
    guard let group = groups.first(where: { $0.title.hasPrefix(title) }), group.actions.contains(.stop) else {
      print("No stoppable row titled \"\(title)\".")
      exit(1)
    }
    print(await GroupActionRunner.run(.stop, on: group))
    exit(0)
  }

  private func refreshGroups() async {
    guard !isRefreshingGroups else { return }
    isRefreshingGroups = true
    defer { isRefreshingGroups = false }
    let snapshot = await processReader.read()
    groups = groupBuilder.build(
      snapshot: snapshot, apps: RunningAppCatalog.current(), selfPid: getpid())
    lastUpdated = snapshot.takenAt
    if let cpuSnapshot = await cpuReader.sample() {
      cpuUsage = cpuSnapshot.host
      cpuGroups = CPUGroupBuilder.build(snapshot: cpuSnapshot, memoryGroups: groups)
    }
  }
}
