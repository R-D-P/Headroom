import SwiftUI

struct PanelView: View {
  let monitor: MemoryMonitor
  let loginItem: LoginItem

  @AppStorage("selectedPanelTab") private var selectedTab = PanelTab.memory
  @AppStorage("summaryCollapsed") private var isSummaryCollapsed = false
  @AppStorage("memoryListSort") private var memorySort = ListSort(key: .memory)
  @AppStorage("cpuListSort") private var cpuSort = ListSort(key: .cpu)

  /// Roughly the height the full summary gives up when folded, handed to the list instead so the
  /// panel stays about the same size.
  private static let collapsedSummaryHeight: CGFloat = 260

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 14) {
        PanelTitleBar(
          selectedTab: $selectedTab, isSummaryCollapsed: $isSummaryCollapsed, monitor: monitor)
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
        MemoryOverviewView(memory: memory, isCollapsed: isSummaryCollapsed)
      }
    case .cpu:
      if let usage = monitor.cpuUsage {
        CPUOverviewView(usage: usage, isCollapsed: isSummaryCollapsed)
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
        cpuShareByGroupId: cpuShareByGroupId,
        busyGroupIds: monitor.busyGroupIds,
        sort: $memorySort,
        height: listHeight(460),
        onAction: { action, group in monitor.perform(action, on: group) }
      )
    case .cpu:
      CPUGroupListView(
        groups: monitor.cpuGroups,
        coreCount: monitor.cpuUsage?.cores.total,
        busyGroupIds: monitor.busyGroupIds,
        sort: $cpuSort,
        height: listHeight(400),
        onAction: { action, group in monitor.perform(action, on: group) }
      )
    }
  }

  private func listHeight(_ height: CGFloat) -> CGFloat {
    isSummaryCollapsed ? height + Self.collapsedSummaryHeight : height
  }

  /// Each RAM-tab row's CPU share. macOS's share is everything not counted under your own rows.
  private var cpuShareByGroupId: [String: Double] {
    monitor.cpuGroups.reduce(into: [:]) { shares, row in
      shares[row.memoryGroup?.id ?? GroupKey.macOS.id, default: 0] += row.share
    }
  }
}
