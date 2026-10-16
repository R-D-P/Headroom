import SwiftUI

struct CPUOverviewView: View {
  let usage: HostCPUUsage
  let isCollapsed: Bool

  var body: some View {
    if isCollapsed {
      CompactSummaryView(
        inUse: PercentFormatting.string(usage.inUse), freeCaption: "idle",
        free: PercentFormatting.string(usage.idle), freeTint: idleTint
      ) {
        CPUBarView(usage: usage)
      }
    } else {
      expanded
    }
  }

  private var expanded: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .bottom) {
        HeadlineNumberView(
          caption: "In use", value: PercentFormatting.string(usage.inUse), tint: .primary,
          alignment: .leading)
        Spacer()
        HeadlineNumberView(
          caption: "Idle", value: PercentFormatting.string(usage.idle), tint: idleTint,
          alignment: .trailing)
      }
      CPUBarView(usage: usage)
      CPUTableView(usage: usage)
      Text(usage.advice)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }

  private var idleTint: Color {
    switch usage.idle {
    case ..<0.2: .red
    case ..<0.5: .yellow
    default: .green
    }
  }
}
