import SwiftUI

struct CPUGroupListView: View {
  let groups: [CPUGroup]
  let coreCount: Int?
  let busyGroupIds: Set<String>
  let onAction: (GroupAction, MemoryGroup) -> Void

  @State private var showsQuietGroups = false

  /// Rows using less than this share of the Mac hide behind "Show quieter items".
  private static let quietThreshold = 0.005

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 2) {
        if let coreCount {
          Text("Busiest first. Percentages are of your whole Mac (all \(coreCount) cores).")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        ForEach(visibleGroups) { group in
          CPUGroupRowView(
            group: group,
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
    .frame(height: 400)
  }

  private var visibleGroups: [CPUGroup] {
    guard !showsQuietGroups else { return groups }
    return groups.filter { $0.share >= Self.quietThreshold }
  }

  private var quietGroupCount: Int {
    groups.count { $0.share < Self.quietThreshold }
  }
}
