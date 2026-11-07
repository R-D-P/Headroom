import SwiftUI

/// One reading of the internal battery, in the units people quote: percent, mAh, watts.
struct BatteryStatus: Sendable, Equatable {
  enum State: Sendable, Equatable {
    case charging
    case discharging
    /// On the adapter but holding, usually at a charge limit or to protect the battery.
    case notCharging
    case full
  }

  /// 0–1, as macOS shows it in the menu bar.
  let charge: Double
  let state: State
  let isPluggedIn: Bool
  /// What's left right now, in mAh.
  let remainingCapacity: Int?
  /// What the battery holds when full today, in mAh.
  let fullChargeCapacity: Int?
  /// What it held when new, in mAh.
  let designCapacity: Int?
  let cycleCount: Int?
  let designCycleCount: Int?
  /// Positive while charging, negative while draining, in mA.
  let amperage: Int?
  /// In mV.
  let voltage: Int?
  /// In °C. Not every Mac reports it.
  let temperature: Double?
  /// Minutes, missing while macOS is still working it out.
  let minutesToFull: Int?
  let minutesToEmpty: Int?
  /// What the whole Mac is drawing, wherever it comes from, in watts.
  let systemPower: Double?
  let adapter: PowerAdapter?
  /// macOS's own verdict, e.g. "Good" or "Service Recommended".
  let condition: String?
  let isLowPowerModeOn: Bool

  /// Into (positive) or out of (negative) the battery, in watts.
  var batteryPower: Double? {
    guard let amperage, let voltage else { return nil }
    return Double(amperage) * Double(voltage) / 1_000_000
  }

  /// Today's full charge as a share of the design capacity.
  var health: Double? {
    guard let fullChargeCapacity, let designCapacity, designCapacity > 0 else { return nil }
    return min(1, Double(fullChargeCapacity) / Double(designCapacity))
  }

  /// The status tile.
  var shortTitle: String {
    switch state {
    case .charging: "Charging"
    case .discharging: "On battery"
    case .notCharging: "Not charging"
    case .full: "Full"
    }
  }

  /// The badge in the title bar, kept short so it stays on one line beside three tabs.
  var badgeTitle: String {
    switch state {
    case .charging: "Charging"
    case .discharging: "On battery"
    case .notCharging, .full: "On adapter"
    }
  }

  var tint: Color {
    switch state {
    case .charging, .full: .green
    case .notCharging: .yellow
    case .discharging: chargeTint
    }
  }

  var chargeTint: Color {
    switch charge {
    case ..<0.1: .red
    case ..<0.2: .orange
    case ..<0.4: .yellow
    default: .green
    }
  }

  var advice: String {
    if let health, health < 0.8 {
      return "The battery holds \(PercentFormatting.string(health)) of what it did when new. "
        + "Below 80%, Apple recommends a replacement."
    }
    switch state {
    case .charging: return "Charging normally."
    case .full: return "Full. Running from the adapter, so the battery isn't being used."
    case .notCharging:
      return charge >= 0.75
        ? "Holding the charge here to protect the battery (Optimized Charging or a charge limit)."
        : "The adapter isn't charging the battery. It may be too weak for what the Mac is drawing."
    case .discharging:
      if charge < 0.2 { return "Running low. Plug in soon." }
      if isLowPowerModeOn { return "Low Power Mode is on, so the Mac is slowed down to last longer." }
      return "Running from the battery."
    }
  }
}

struct PowerAdapter: Sendable, Equatable {
  /// What was negotiated, which can sit a little under the rating in the name.
  let watts: Int?
  /// Carries the rating, e.g. "96W USB-C Power Adapter".
  let name: String?
  let isWireless: Bool
}
