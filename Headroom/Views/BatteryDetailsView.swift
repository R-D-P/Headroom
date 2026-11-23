import SwiftUI

/// The battery tab's lower half, where the other tabs list apps: how worn the battery is, then
/// the electrical and adapter details.
struct BatteryDetailsView: View {
  let battery: BatteryStatus?
  let isChangingLowPowerMode: Bool
  let isChangingEcoMode: Bool
  /// Whether this Mac's macOS can take a 60% limit. Worked out off the main thread.
  let canSetEcoMode: Bool
  /// The limit is lifted for one full charge, after which Eco Mode comes back.
  let isChargingToFullOnce: Bool
  let height: CGFloat
  let onSetLowPowerMode: (Bool) -> Void
  let onSetEcoMode: (Bool) -> Void
  let onSetFullChargeOnce: (Bool) -> Void

  var body: some View {
    ScrollView {
      if let battery {
        VStack(alignment: .leading, spacing: 18) {
          // First, because it's only there while something is plugged in, and lower down it sat
          // out of sight until the list was scrolled.
          if !battery.accessories.isEmpty {
            section("Charging from this Mac") {
              ForEach(battery.accessories) { accessory in
                TableRowView(
                  title: accessory.title,
                  // Measured at the port, so it covers anything else on the same cable too.
                  explanation: accessory.limitWatts.map { "Whole port, up to \(BatteryFormatting.watts($0))" }
                    ?? "Whole port",
                  value: BatteryFormatting.watts(accessory.watts), color: .orange, dotPlacement: .beforeValue,
                  titleFitsContent: true)
              }
            }
          }
          BatteryHealthView(battery: battery)
          section("Power flow") {
            BatteryPowerFlowRows(battery: battery)
          }
          section("Details") {
            TableRowView(
              title: "Adapter", explanation: battery.adapter?.name,
              value: adapterValue(battery), dotPlacement: .beforeValue)
            if let voltage = battery.voltage {
              TableRowView(
                title: "Voltage", explanation: "At the battery",
                value: String(format: "%.2f V", Double(voltage) / 1000), dotPlacement: .beforeValue)
            }
            if let amperage = battery.amperage {
              TableRowView(
                title: "Current", explanation: currentExplanation(amperage),
                value: BatteryFormatting.milliamps(abs(amperage)), dotPlacement: .beforeValue)
            }
            if let temperature = battery.temperature {
              TableRowView(title: "Temperature", value: String(format: "%.1f °C", temperature), dotPlacement: .beforeValue)
            }
            if canSetEcoMode {
              SwitchRow(
                title: "Eco Mode", explanation: "Stops charging at \(EcoMode.percent)%",
                withoutHelper: .unavailable,
                isOn: battery.isEcoModeOn, isChanging: isChangingEcoMode, onSet: onSetEcoMode)
              if battery.isEcoModeOn || isChargingToFullOnce {
                SwitchRow(
                  title: "Charge to full", explanation: "Once, then Eco Mode returns",
                  withoutHelper: .unavailable,
                  isOn: isChargingToFullOnce, isChanging: isChangingEcoMode, onSet: onSetFullChargeOnce)
              }
            }
            SwitchRow(
              title: "Low Power Mode", explanation: "Slows the Mac to last longer",
              withoutHelper: .asksForPassword,
              isOn: battery.isLowPowerModeOn, isChanging: isChangingLowPowerMode,
              onSet: onSetLowPowerMode)
          }
        }
        .padding(16)
      } else {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(40)
      }
    }
    .frame(height: height)
  }

  private func adapterValue(_ battery: BatteryStatus) -> String {
    guard let adapter = battery.adapter else { return "Not connected" }
    return adapter.watts.map { "\($0) W max" } ?? "Connected"
  }

  private func currentExplanation(_ amperage: Int) -> String {
    switch amperage {
    case 1...: "Into the battery"
    case ..<0: "Out of the battery"
    default: "Nothing in or out"
    }
  }

  private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      SectionHeader(title: title)
      rows()
    }
  }
}

/// Laid out like a table row, with a switch where the value would be.
struct SwitchRow: View {
  let title: String
  /// What it does. Until the helper is allowed, the row says what will happen instead.
  let explanation: String
  let withoutHelper: WithoutHelper
  let isOn: Bool
  let isChanging: Bool
  let onSet: (Bool) -> Void

  var body: some View {
    HStack(spacing: 8) {
      Text(title)
        .frame(width: 104, alignment: .leading)
      Text(note)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      if isChanging {
        ProgressView().controlSize(.mini)
      }
      Toggle(title, isOn: Binding(get: { isOn }, set: { onSet($0) }))
        .toggleStyle(.switch)
        .controlSize(.mini)
        .labelsHidden()
        .disabled(isChanging || !isUsable)
    }
    .font(.caption)
  }

  /// What a build that can't have a helper (anything but the installed app) does about it.
  enum WithoutHelper {
    case asksForPassword
    case unavailable
  }

  private var isUsable: Bool { PrivilegedHelper.isInstalled || withoutHelper == .asksForPassword }

  private var note: String {
    if PrivilegedHelper.isAllowed { return explanation }
    if PrivilegedHelper.isInstalled { return "Asks once for permission" }
    return withoutHelper == .asksForPassword ? "Asks for your password" : "Only in the installed app"
  }
}

/// Where the watts are coming from and going to right now: adapter in, then the split between
/// charging the battery and running the Mac; or, unplugged, what the battery is giving up.
struct BatteryPowerFlowRows: View {
  let battery: BatteryStatus

  /// Under this the battery is as good as idle; the gauge jitters by a few milliwatts.
  private static let idleWatts = 0.05

  var body: some View {
    if battery.isSettling {
      TableRowView(
        title: battery.isPluggedIn ? "From adapter" : "From battery",
        explanation: "Measuring, up to a minute", value: "…", dotPlacement: .beforeValue)
    } else {
      settledRows
    }
  }

  @ViewBuilder
  private var settledRows: some View {
    let batteryPower = battery.batteryPower ?? 0
    if battery.isPluggedIn {
      TableRowView(
        title: "From adapter",
        explanation: battery.isHeldOffAdapter ? "Paused above the limit" : adapterExplanation,
        value: battery.isHeldOffAdapter ? BatteryFormatting.watts(0) : watts(battery.adapterPower),
        color: .blue, dotPlacement: .beforeValue)
    }
    if batteryPower > Self.idleWatts {
      TableRowView(
        title: "To battery", explanation: "Charging it",
        value: watts(batteryPower), color: .green, dotPlacement: .beforeValue)
    } else if batteryPower < -Self.idleWatts {
      TableRowView(
        title: "From battery",
        explanation: fromBatteryExplanation,
        value: watts(-batteryPower), color: battery.chargeTint, dotPlacement: .beforeValue)
    } else {
      TableRowView(
        title: "To battery", explanation: "Not charging",
        value: watts(0), color: MemorySegment.unused.color, dotPlacement: .beforeValue)
    }
    if battery.accessoryPower > Self.idleWatts {
      TableRowView(
        title: "To accessories",
        explanation: battery.accessories.count == 1 ? "Out through 1 port" : "Out through \(battery.accessories.count) ports",
        value: watts(battery.accessoryPower), color: .orange, dotPlacement: .beforeValue)
    }
    TableRowView(
      title: "To the Mac", explanation: "Running the Mac itself",
      value: watts(battery.macPower), color: .purple, dotPlacement: .beforeValue)
  }

  private var fromBatteryExplanation: String {
    guard battery.isPluggedIn else { return "Draining" }
    return battery.isDrainingToLimit ? "Down to the charge limit" : "The adapter can't keep up"
  }

  private var adapterExplanation: String {
    guard let rating = battery.adapter?.watts else { return "What it's delivering now" }
    return "Of the \(rating) W it can supply"
  }

  private func watts(_ value: Double?) -> String {
    value.map(BatteryFormatting.watts) ?? "–"
  }
}

/// Health as a bar the width of the battery when new: what's charged, what's left to charge, and
/// what's been lost to wear, with the same dot-keyed rows as the RAM tab.
struct BatteryHealthView: View {
  let battery: BatteryStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        SectionHeader(title: "Health")
        Spacer()
        if let health = battery.health {
          Text(PercentFormatting.string(health))
            .font(.title3.weight(.semibold).monospacedDigit())
            .foregroundStyle(healthTint(health))
          Text(verdict(health))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      if let remaining = battery.remainingCapacity, let full = battery.fullChargeCapacity,
        let design = battery.designCapacity, design > 0
      {
        bar(remaining: remaining, full: full, design: design)
        VStack(spacing: 5) {
          TableRowView(
            title: "Available", explanation: "Charge in the battery now",
            value: BatteryFormatting.milliampHours(remaining), color: battery.chargeTint, dotPlacement: .beforeValue)
          TableRowView(
            title: "Room to charge", explanation: "Up to today's full charge",
            value: BatteryFormatting.milliampHours(max(0, full - remaining)),
            color: battery.chargeTint.opacity(0.35), dotPlacement: .beforeValue)
          TableRowView(
            title: "Lost to wear", explanation: "Gone for good as it ages",
            value: BatteryFormatting.milliampHours(max(0, design - full)),
            color: MemorySegment.unused.color, dotPlacement: .beforeValue)
          TableRowView(
            title: "When new", value: BatteryFormatting.milliampHours(design), isTotal: true, dotPlacement: .beforeValue)
        }
      }
      if let cycles = battery.cycleCount {
        Divider()
        TableRowView(
          title: "Cycles",
          explanation: battery.designCycleCount.map { "Rated for \($0.formatted())" },
          value: cycles.formatted(), dotPlacement: .beforeValue)
      }
    }
  }

  private func bar(remaining: Int, full: Int, design: Int) -> some View {
    GeometryReader { geometry in
      let width = { (mAh: Int) in geometry.size.width * min(1, Double(max(0, mAh)) / Double(design)) }
      HStack(spacing: 1.5) {
        Rectangle()
          .fill(battery.chargeTint.gradient)
          .frame(width: width(remaining))
        Rectangle()
          .fill(battery.chargeTint.opacity(0.35))
          .frame(width: width(full - remaining))
        Spacer(minLength: 0)
      }
    }
    .frame(height: 10)
    .background(MemorySegment.unused.color)
    .clipShape(Capsule())
  }

  private func verdict(_ health: Double) -> String {
    if let condition = battery.condition, !condition.isEmpty { return condition }
    return switch health {
    case ..<0.8: "Service recommended"
    case ..<0.9: "Worn"
    default: "Good"
    }
  }

  private func healthTint(_ health: Double) -> Color {
    switch health {
    case ..<0.8: .orange
    case ..<0.9: .yellow
    default: .green
    }
  }
}

struct SectionHeader: View {
  let title: String

  var body: some View {
    Text(title.uppercased())
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
  }
}
