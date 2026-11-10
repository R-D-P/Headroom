import AppKit
import Observation

/// Owns the numbers on screen. Refreshes memory, CPU and battery every 5 seconds for the menu bar,
/// and the full per-process RAM and CPU breakdown every 2 seconds while the panel is open.
@MainActor
@Observable
final class MemoryMonitor {
  private(set) var systemMemory: SystemMemory?
  private(set) var groups: [MemoryGroup] = []
  private(set) var cpuUsage: HostCPUUsage?
  private(set) var cpuGroups: [CPUGroup] = []
  private(set) var battery: BatteryStatus? {
    didSet { menuBarPulse.setActive(battery?.warning == .critical) }
  }
  let menuBarPulse = PulseClock()
  private(set) var lastUpdated: Date?
  private(set) var busyGroupIds: Set<String> = []
  private(set) var statusMessage: String?
  private(set) var isChangingLowPowerMode = false

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
      if let isOn = LaunchOptions.lowPowerModeToSet {
        return await setLowPowerModeAndExit(isOn)
      }
      guard !LaunchOptions.printsGroupsAndExits else { return await printGroupsAndExit() }
      await runLoop()
    }
  }

  func panelDidAppear() {
    visiblePanelCount += 1
    systemMemory = SystemMemoryReader.read()
    battery = BatteryReader.read()
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

  func setLowPowerMode(_ isOn: Bool) {
    guard !isChangingLowPowerMode else { return }
    isChangingLowPowerMode = true
    statusMessage = nil
    Task {
      switch await LowPowerMode.set(isOn) {
      case .changed: statusMessage = "Low Power Mode is \(isOn ? "on" : "off")."
      case .needsApproval:
        statusMessage = "Allow Headroom in Login Items, then flip the switch again."
      case .cancelled: break
      case .failed: statusMessage = "Couldn't change Low Power Mode."
      }
      isChangingLowPowerMode = false
      battery = BatteryReader.read()
    }
  }

  private func runLoop() async {
    while !Task.isCancelled {
      systemMemory = SystemMemoryReader.read()
      battery = BatteryReader.read()
      if isPanelVisible || groups.isEmpty {
        await refreshGroups()
      } else {
        // Feeds the menu bar, and keeps a recent reading on hand for when the CPU tab opens.
        if let host = await cpuReader.sample()?.host { cpuUsage = host }
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

  private func setLowPowerModeAndExit(_ isOn: Bool) async {
    let outcome = await LowPowerMode.set(isOn)
    print("Low Power Mode \(isOn ? "on" : "off"): \(outcome)")
    exit(outcome == .changed ? 0 : 1)
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
