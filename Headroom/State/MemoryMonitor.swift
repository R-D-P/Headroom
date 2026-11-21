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
  private(set) var isChangingEcoMode = false
  /// The limit is lifted for one full charge, after which Eco Mode comes back.
  private(set) var isChargingToFullOnce = EcoMode.returnsAfterFullCharge {
    didSet { battery?.ecoModeReturnsWhenFull = isChargingToFullOnce }
  }
  @ObservationIgnored private var lastResumeAttempt = Date.distantPast
  /// True once macOS has answered about its charge limit, so the Eco Mode switch can be shown.
  private(set) var canSetEcoMode = false
  /// Only needed by the Battery tab, so only refreshed while the panel is open.
  private var chargeLimit: ChargeLimit? {
    didSet { battery?.chargeLimit = chargeLimit?.activePercent }
  }
  /// The power figures lag for up to a minute after the plug goes in or out, and no longer.
  @ObservationIgnored private var wasPluggedIn: Bool?
  @ObservationIgnored private var plugChangedAt = Date()
  private static let settlingSeconds = 90.0

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
      if let isOn = LaunchOptions.ecoModeToSet {
        return await setEcoModeAndExit(isOn)
      }
      if let isOn = LaunchOptions.fullChargeOnceToSet {
        return await setFullChargeOnceAndExit(isOn)
      }
      guard !LaunchOptions.printsGroupsAndExits else { return await printGroupsAndExit() }
      await runLoop()
    }
  }

  func panelDidAppear() {
    visiblePanelCount += 1
    systemMemory = SystemMemoryReader.read()
    battery = readBattery()
    Task { await refreshChargeLimit() }
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
      battery = readBattery()
    }
  }

  func setEcoMode(_ isOn: Bool) {
    guard !isChangingEcoMode else { return }
    isChangingEcoMode = true
    statusMessage = nil
    Task {
      switch await EcoMode.set(isOn) {
      case .changed:
        statusMessage =
          isOn ? "Eco Mode is on. Charging stops at \(EcoMode.percent)%." : "Eco Mode is off."
      case .needsApproval:
        statusMessage = "Allow Headroom in Login Items, then flip the switch again."
      case .cancelled: break
      case .failed: statusMessage = "Couldn't change Eco Mode."
      }
      isChargingToFullOnce = EcoMode.returnsAfterFullCharge
      await refreshChargeLimit()
      isChangingEcoMode = false
    }
  }

  /// On: charge to full this once. Off: call it off and put the limit straight back.
  func setFullChargeOnce(_ isOn: Bool) {
    guard !isChangingEcoMode else { return }
    isChangingEcoMode = true
    statusMessage = nil
    Task {
      switch await (isOn ? EcoMode.chargeToFullOnce() : EcoMode.resume()) {
      case .changed:
        statusMessage =
          isOn
          ? "Charging to full this once. Eco Mode comes back at 100%."
          : "Eco Mode is back on. Charging stops at \(EcoMode.percent)%."
      case .needsApproval:
        statusMessage = "Allow Headroom in Login Items, then flip the switch again."
      case .cancelled: break
      case .failed: statusMessage = "Couldn't change the charge limit."
      }
      isChargingToFullOnce = EcoMode.returnsAfterFullCharge
      await refreshChargeLimit()
      isChangingEcoMode = false
    }
  }

  /// The other half of "Charge to full": once the battery is full, the limit goes back on.
  private func resumeEcoModeIfFullyCharged() async {
    guard isChargingToFullOnce, !isChangingEcoMode, let battery, battery.charge >= 0.995,
      Date().timeIntervalSince(lastResumeAttempt) > Self.resumeRetrySeconds
    else { return }
    lastResumeAttempt = Date()
    isChangingEcoMode = true
    if case .changed = await EcoMode.resume() {
      statusMessage = "Fully charged. Eco Mode is back on."
    }
    isChargingToFullOnce = EcoMode.returnsAfterFullCharge
    await refreshChargeLimit()
    isChangingEcoMode = false
  }

  /// How long to leave it before asking the helper again when putting the limit back fails.
  private static let resumeRetrySeconds = 60.0

  private func readBattery() -> BatteryStatus? {
    var battery = BatteryReader.read()
    if let isPluggedIn = battery?.isPluggedIn, isPluggedIn != wasPluggedIn {
      wasPluggedIn = isPluggedIn
      plugChangedAt = Date()
    }
    if battery?.isSettling == true, Date().timeIntervalSince(plugChangedAt) > Self.settlingSeconds {
      battery = BatteryReader.read(canBeSettling: false)
    }
    battery?.chargeLimit = chargeLimit?.activePercent
    battery?.ecoModeReturnsWhenFull = isChargingToFullOnce
    return battery
  }

  private func refreshChargeLimit() async {
    guard BatteryReader.hasBattery, let limit = await ChargeLimitClient.readInBackground() else { return }
    chargeLimit = limit
    canSetEcoMode = true
  }

  private func runLoop() async {
    while !Task.isCancelled {
      systemMemory = SystemMemoryReader.read()
      battery = readBattery()
      await resumeEcoModeIfFullyCharged()
      if isPanelVisible { await refreshChargeLimit() }
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

  private func setEcoModeAndExit(_ isOn: Bool) async {
    let outcome = await EcoMode.set(isOn)
    let limit = await ChargeLimitClient.readInBackground()
    print("Eco Mode \(isOn ? "on" : "off"): \(outcome), charge limit now \(limit.map { "\($0.percent)%" } ?? "unknown")")
    exit(outcome == .changed ? 0 : 1)
  }

  private func setFullChargeOnceAndExit(_ isOn: Bool) async {
    let outcome = await (isOn ? EcoMode.chargeToFullOnce() : EcoMode.resume())
    let limit = await ChargeLimitClient.readInBackground()
    print("Charge to full \(isOn ? "on" : "off"): \(outcome), charge limit now \(limit.map { "\($0.percent)%" } ?? "unknown")")
    exit(outcome == .changed ? 0 : 1)
  }

  private func stopGroupAndExit(titled title: String) async {
    // An empty title would match every row, the largest first.
    guard !title.isEmpty else {
      print("--stop needs a row title.")
      exit(1)
    }
    await refreshGroups()
    guard let group = groups.first(where: { $0.title.hasPrefix(title) && $0.actions.contains(.stop) }) else {
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
