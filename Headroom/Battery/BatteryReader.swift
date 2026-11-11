import Foundation
import IOKit
import IOKit.ps

/// Reads the internal battery from the I/O Registry (AppleSmartBattery), where macOS keeps the
/// raw figures that System Settings rounds away. Returns nil on Macs without a battery.
enum BatteryReader {
  /// Checked once: a Mac doesn't grow a battery while running. Desktop Macs still have the
  /// AppleSmartBattery entry, just with nothing installed, so its presence alone proves nothing.
  static let hasBattery: Bool = {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    guard service != 0 else { return false }
    defer { IOObjectRelease(service) }
    let installed = IORegistryEntryCreateCFProperty(
      service, "BatteryInstalled" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool
    return installed != false && PowerSourceInfo.read() != nil
  }()

  /// macOS uses this in place of a time it hasn't worked out yet.
  private static let unknownMinutes = 65535

  static func read() -> BatteryStatus? {
    guard hasBattery else { return nil }
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }

    var unmanaged: Unmanaged<CFMutableDictionary>?
    guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
      let properties = unmanaged?.takeRetainedValue() as? [String: Any]
    else { return nil }
    let battery = Properties(properties)
    // Newer macOS versions keep some figures only in the nested BatteryData dictionary.
    let batteryData = battery.dictionary("BatteryData")
    let int = { (key: String) in battery.int(key) ?? batteryData?.int(key) }
    let powerSource = PowerSourceInfo.read()

    // On Apple silicon CurrentCapacity/MaxCapacity are percent and the mAh live under the
    // Apple-prefixed keys. Intel Macs report mAh in the plain keys, which then run past 100.
    let reportsPercent = (int("MaxCapacity") ?? 0) <= 100
    let remaining = int("AppleRawCurrentCapacity") ?? (reportsPercent ? nil : int("CurrentCapacity"))
    let full =
      int("AppleRawMaxCapacity") ?? int("FullChargeCapacity")
      ?? (reportsPercent ? nil : int("MaxCapacity"))
    let charge = powerSource?.charge ?? fraction(remaining, of: full) ?? 0

    let isPluggedIn =
      LaunchOptions.simulatedCharge == nil && battery.bool("ExternalConnected") ?? false
    let isCharging = battery.bool("IsCharging") ?? false
    let isFull = battery.bool("FullyCharged") ?? false
    let state: BatteryStatus.State =
      switch (isPluggedIn, isCharging, isFull) {
      case (false, _, _): .discharging
      case (true, true, _): .charging
      case (true, false, true): .full
      case (true, false, false): .notCharging
      }

    let telemetry = battery.dictionary("PowerTelemetryData")
    let watts = { (key: String) -> Double? in
      telemetry?.int(key).flatMap { $0 > 0 ? Double($0) / 1000 : nil }
    }

    // The plug state flips at once, but the gauge behind the electrical figures only refreshes
    // about once a minute. Until it does, they still describe the moment before: charging current
    // with no adapter, or no adapter power with one attached. Better to show nothing than that.
    let rawAmperage = battery.int("InstantAmperage") ?? battery.int("Amperage")
    let adapterPower = isPluggedIn ? watts("SystemPowerIn") : nil
    let isSettling =
      LaunchOptions.simulatedCharge == nil
      && (isPluggedIn
        ? telemetry != nil && adapterPower == nil
        : (rawAmperage ?? 0) > 0 || (telemetry?.int("SystemPowerIn") ?? 0) > 0)

    return BatteryStatus(
      charge: LaunchOptions.simulatedCharge ?? charge,
      state: state,
      isPluggedIn: isPluggedIn,
      remainingCapacity: remaining,
      fullChargeCapacity: full,
      designCapacity: int("DesignCapacity"),
      cycleCount: int("CycleCount"),
      designCycleCount: int("DesignCycleCount9C"),
      amperage: isSettling ? nil : rawAmperage,
      voltage: battery.int("Voltage"),
      temperature: int("Temperature").map { Double($0) / 100 },
      minutesToFull: state == .charging ? minutes(battery.int("AvgTimeToFull")) : nil,
      minutesToEmpty: state == .discharging
        ? minutes(battery.int("TimeRemaining") ?? battery.int("AvgTimeToEmpty")) : nil,
      adapterPower: adapterPower,
      systemLoad: isSettling ? nil : watts("SystemLoad"),
      isSettling: isSettling,
      adapter: isPluggedIn ? adapter(from: battery.dictionary("AdapterDetails")) : nil,
      condition: powerSource?.condition,
      isLowPowerModeOn: ProcessInfo.processInfo.isLowPowerModeEnabled
    )
  }

  private static func minutes(_ value: Int?) -> Int? {
    guard let value, value > 0, value < unknownMinutes else { return nil }
    return value
  }

  private static func fraction(_ part: Int?, of whole: Int?) -> Double? {
    guard let part, let whole, whole > 0 else { return nil }
    return min(1, Double(part) / Double(whole))
  }

  private static func adapter(from details: Properties?) -> PowerAdapter {
    PowerAdapter(
      watts: details?.int("Watts"),
      name: (details?.string("Name") ?? details?.string("Description"))?
        .trimmingCharacters(in: .whitespaces),
      isWireless: details?.bool("IsWireless") ?? false
    )
  }
}

/// The higher-level power source list, for the rounded charge macOS shows and its health verdict.
private struct PowerSourceInfo {
  let charge: Double?
  let condition: String?

  static func read() -> PowerSourceInfo? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
      let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
    else { return nil }
    for source in sources {
      guard
        let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
          as? [String: Any],
        description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
      else { continue }
      let current = description[kIOPSCurrentCapacityKey] as? Int
      let max = description[kIOPSMaxCapacityKey] as? Int
      let charge = current.flatMap { current in max.map { Double(current) / Double(Swift.max(1, $0)) } }
      return PowerSourceInfo(
        charge: charge.map { min(1, $0) },
        condition: description[kIOPSBatteryHealthKey] as? String)
    }
    return nil
  }
}

/// Typed lookups into an I/O Registry dictionary. Signed values such as Amperage are stored as
/// unsigned 64-bit numbers, so they're read back through their bit pattern.
private struct Properties {
  let values: [String: Any]

  init(_ values: [String: Any]) { self.values = values }

  func int(_ key: String) -> Int? {
    guard let number = values[key] as? NSNumber else { return nil }
    return Int(Int64(bitPattern: number.uint64Value))
  }

  func bool(_ key: String) -> Bool? { (values[key] as? NSNumber)?.boolValue }

  func string(_ key: String) -> String? { values[key] as? String }

  func dictionary(_ key: String) -> Properties? {
    (values[key] as? [String: Any]).map(Properties.init)
  }
}
