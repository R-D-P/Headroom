import SwiftUI

struct PanelView: View {
  let monitor: MemoryMonitor
  let loginItem: LoginItem

  @AppStorage("selectedPanelTab") private var selectedTab = PanelTab.memory

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 14) {
        PanelTitleBar(selectedTab: $selectedTab, monitor: monitor)
        overview
      }
      .padding(16)
      Divider()
      list
      Divider()
      PanelFooterView(statusMessage: monitor.statusMessage, loginItem: loginItem)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    .frame(width: 460)
    .onAppear { monitor.panelDidAppear() }
    .onDisappear { monitor.panelDidDisappear() }
  }

  @ViewBuilder
  private var overview: some View {
    switch selectedTab {
    case .memory:
      if let memory = monitor.systemMemory {
        MemoryOverviewView(memory: memory)
      }
    case .cpu:
      if let usage = monitor.cpuUsage {
        CPUOverviewView(usage: usage)
      } else {
        MeasuringView()
      }
    }
  }

  @ViewBuilder
  private var list: some View {
    switch selectedTab {
    case .memory:
      GroupListView(
        groups: monitor.groups,
        busyGroupIds: monitor.busyGroupIds,
        onAction: { action, group in monitor.perform(action, on: group) }
      )
    case .cpu:
      CPUGroupListView(
        groups: monitor.cpuGroups,
        coreCount: monitor.cpuUsage?.cores.total,
        busyGroupIds: monitor.busyGroupIds,
        onAction: { action, group in monitor.perform(action, on: group) }
      )
    }
  }
}
