import SwiftUI

struct GroupListView: View {
  let groups: [MemoryGroup]
  let busyGroupIds: Set<String>
  let onAction: (GroupAction, MemoryGroup) -> Void

  @State private var showsSmallGroups = false

  /// Rows smaller than this hide behind "Show smaller items" so the list stays readable.
  private static let smallGroupThreshold: UInt64 = 40 * 1_048_576

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 2) {
        if groups.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity)
            .padding(40)
        }
        ForEach(visibleGroups) { group in
          GroupRowView(group: group, isBusy: busyGroupIds.contains(group.id)) { action in
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
    .frame(height: 460)
  }

  private var visibleGroups: [MemoryGroup] {
    guard !showsSmallGroups else { return groups }
    return groups.filter { $0.footprintBytes >= Self.smallGroupThreshold }
  }

  private var smallGroupCount: Int {
    groups.count { $0.footprintBytes < Self.smallGroupThreshold }
  }
}
