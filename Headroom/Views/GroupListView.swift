import SwiftUI

struct GroupListView: View {
  let groups: [MemoryGroup]
  let cpuShareByGroupId: [String: Double]
  let busyGroupIds: Set<String>
  @Binding var sort: ListSort
  let height: CGFloat
  let onAction: (GroupAction, MemoryGroup) -> Void

  @State private var showsSmallGroups = false

  /// Rows smaller than this hide behind "Show smaller items" so the list stays readable.
  private static let smallGroupThreshold: UInt64 = 40 * 1_048_576

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        SortControl(sort: $sort)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 6)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 2) {
          if groups.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding(40)
          }
          ForEach(visibleGroups) { group in
            GroupRowView(
              group: group,
              cpuShare: cpuShareByGroupId[group.id] ?? 0,
              sortKey: sort.key,
              isBusy: busyGroupIds.contains(group.id)
            ) { action in
              onAction(action, group)
            }
          }
          if smallGroupCount > 0 {
            Button(showsSmallGroups ? "Hide smaller items" : "Show \(smallGroupCount) smaller items") {
              withAnimation(.snappy) { showsSmallGroups.toggle() }
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
          }
        }
        .padding(6)
      }
    }
    .frame(height: height)
  }

  /// macOS stays last whatever the order, because nothing in it can be acted on.
  private var visibleGroups: [MemoryGroup] {
    let shown = showsSmallGroups ? groups : groups.filter { $0.footprintBytes >= Self.smallGroupThreshold }
    let (macOS, others) = (
      shown.filter { $0.id == GroupKey.macOS.id }, shown.filter { $0.id != GroupKey.macOS.id }
    )
    return sort.ordered(others, value: value(of:), title: \.title) + macOS
  }

  private func value(of group: MemoryGroup) -> Double {
    switch sort.key {
    case .memory: Double(group.footprintBytes)
    case .cpu: cpuShareByGroupId[group.id] ?? 0
    }
  }

  private var smallGroupCount: Int {
    groups.count { $0.footprintBytes < Self.smallGroupThreshold }
  }
}
