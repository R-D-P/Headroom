import SwiftUI

struct CPUGroupListView: View {
  let groups: [CPUGroup]
  let coreCount: Int?
  let busyGroupIds: Set<String>
  @Binding var sort: ListSort
  let height: CGFloat
  let onAction: (GroupAction, MemoryGroup) -> Void

  @State private var showsQuietGroups = false

  /// Rows using less than this share of the Mac hide behind "Show quieter items".
  private static let quietThreshold = 0.005

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        if let coreCount {
          Text("% of your whole Mac (all \(coreCount) cores)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        SortControl(sort: $sort)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 6)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 2) {
          ForEach(visibleGroups) { group in
            CPUGroupRowView(
              group: group,
              sortKey: sort.key,
              isBusy: busyGroupIds.contains(group.memoryGroup?.id ?? ""),
              onAction: onAction
            )
          }
          if quietGroupCount > 0 {
            Button(showsQuietGroups ? "Hide quieter items" : "Show \(quietGroupCount) quieter items") {
              withAnimation(.snappy) { showsQuietGroups.toggle() }
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

  private var visibleGroups: [CPUGroup] {
    let shown = showsQuietGroups ? groups : groups.filter { $0.share >= Self.quietThreshold }
    return sort.ordered(shown, value: value(of:), title: \.title)
  }

  /// macOS jobs have no RAM figure of their own, so sorting by RAM puts them together at one end.
  private func value(of group: CPUGroup) -> Double {
    switch sort.key {
    case .memory: Double(group.memoryGroup?.footprintBytes ?? 0)
    case .cpu: group.share
    }
  }

  private var quietGroupCount: Int {
    groups.count { $0.share < Self.quietThreshold }
  }
}
