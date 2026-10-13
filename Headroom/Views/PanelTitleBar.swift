import SwiftUI

/// "Headroom", the RAM/CPU switch, and the status badge for the tab on show.
struct PanelTitleBar: View {
  @Binding var selectedTab: PanelTab
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
