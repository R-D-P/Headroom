import SwiftUI

/// "Headroom", the RAM/CPU switch, the status badge for the tab on show, and the button that
/// folds the summary away.
struct PanelTitleBar: View {
  @Binding var selectedTab: PanelTab
  @Binding var isSummaryCollapsed: Bool
  let monitor: MemoryMonitor

  var body: some View {
    HStack(spacing: 12) {
      Text("Headroom")
        .font(.headline)
      Picker("View", selection: $selectedTab) {
        ForEach(PanelTab.allCases) { tab in
          Text(tab.title).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 120)
      Spacer()
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
    }
  }
}
