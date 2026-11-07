import SwiftUI

/// Charge, how long it lasts (or how long until full), and how fast power is going in or out.
struct BatteryOverviewView: View {
  let battery: BatteryStatus
  let isCollapsed: Bool

  var body: some View {
    if isCollapsed {
      CompactSummaryView(
        inUse: PercentFormatting.string(battery.charge), inUseCaption: "charged",
        freeCaption: headline.caption.lowercased(), free: headline.value, freeTint: .primary
      ) {
        BatteryBarView(battery: battery)
      }
    } else {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .bottom) {
          HeadlineNumberView(
            caption: "Charge", value: PercentFormatting.string(battery.charge),
            tint: battery.chargeTint, alignment: .leading)
          Spacer()
          HeadlineNumberView(
            caption: headline.caption, value: headline.value, tint: .primary, alignment: .trailing)
        }
        BatteryBarView(battery: battery)
        HStack(spacing: 8) {
          StatTile(caption: "Status", value: battery.shortTitle, dot: battery.tint)
          StatTile(caption: "Charge rate", value: rate)
          StatTile(caption: "Mac drawing", value: battery.systemPower.map(BatteryFormatting.watts) ?? "–")
        }
        Text(battery.advice)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  /// The right-hand number: time while it's moving, otherwise how much charge is in hand.
  private var headline: (caption: String, value: String) {
    switch battery.state {
    case .charging:
      ("Until full", battery.minutesToFull.map(BatteryFormatting.duration) ?? "…")
    case .discharging:
      ("Time left", battery.minutesToEmpty.map(BatteryFormatting.duration) ?? "…")
    case .notCharging, .full:
      ("Available", battery.remainingCapacity.map(BatteryFormatting.milliampHours) ?? "–")
    }
  }

  private var rate: String {
    guard let power = battery.batteryPower, abs(power) > 0.05 else { return "Idle" }
    return (power > 0 ? "+" : "−") + BatteryFormatting.watts(abs(power))
  }
}

/// A small labelled number in a rounded box, three to a row.
struct StatTile: View {
  let caption: String
  let value: String
  var dot: Color?

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(caption.uppercased())
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      HStack(spacing: 5) {
        if let dot {
          Circle().fill(dot).frame(width: 7, height: 7)
        }
        Text(value)
          .font(.callout.weight(.semibold).monospacedDigit())
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
  }
}

struct BatteryBarView: View {
  let battery: BatteryStatus

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        Rectangle()
          .fill(battery.chargeTint.gradient)
          .frame(width: geometry.size.width * battery.charge)
        Spacer(minLength: 0)
      }
    }
    .frame(height: 12)
    .background(MemorySegment.unused.color)
    .clipShape(Capsule())
    .animation(.smooth, value: battery.charge)
  }
}
