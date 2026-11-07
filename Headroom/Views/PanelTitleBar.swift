import SwiftUI

/// The RAM/CPU/Battery switch on the left, then the status badge for the tab on show and the
/// button that folds the summary away. Nothing on the left changes width between tabs, so the
/// switch never moves.
struct PanelTitleBar: View {
  @Binding var selectedTab: PanelTab
  @Binding var isSummaryCollapsed: Bool
  let monitor: MemoryMonitor

  var body: some View {
    HStack(spacing: 12) {
      Picker("View", selection: $selectedTab) {
        ForEach(PanelTab.available) { tab in
          Text(tab.title).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: CGFloat(PanelTab.available.count) * 72)
      Spacer(minLength: 8)
      badge
      Button {
        withAnimation(.snappy) { isSummaryCollapsed.toggle() }
      } label: {
        Image(systemName: "chevron.up")
          .font(.caption.weight(.semibold))
          .rotationEffect(.degrees(isSummaryCollapsed ? 180 : 0))
          .frame(width: 16, height: 16)
          .contentShape(Rectangle())
      }
      .buttonStyle(.borderless)
      .help(isSummaryCollapsed ? "Show summary" : "Hide summary")
    }
  }

  @ViewBuilder
  private var badge: some View {
    switch selectedTab {
    case .memory:
      if let memory = monitor.systemMemory {
        StatusBadge(title: "Pressure: \(memory.pressure.title)", tint: memory.pressure.tint)
      }
    case .cpu:
      if let usage = monitor.cpuUsage {
        StatusBadge(title: usage.thermalState.title, tint: usage.thermalState.tint)
      }
    case .battery:
      if let battery = monitor.battery {
        StatusBadge(title: battery.badgeTitle, tint: battery.tint)
      }
    }
  }
}
