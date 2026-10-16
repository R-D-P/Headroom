import SwiftUI

/// One app, dev server or session. Click to see its processes.
struct GroupRowView: View {
  let group: MemoryGroup
  let cpuShare: Double
  let sortKey: ListSort.Key
  let isBusy: Bool
  let onAction: (GroupAction) -> Void

  @State private var isExpanded = false
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 10) {
        GroupIconView(kind: group.kind)
        GroupSummaryView(
          title: group.title, details: group.details, explanation: group.explanation,
          isOrphaned: group.isOrphaned, isExpanded: isExpanded
        ) {
          HStack(spacing: 8) {
            ActionSegmentsView(group: group, isBusy: isBusy, onAction: onAction)
            MetricSegmentsView(
              memory: ByteFormatting.string(group.footprintBytes),
              memoryTint: FootprintLevel.of(group)?.tint ?? .primary,
              cpu: PercentFormatting.string(cpuShare),
              sortKey: sortKey)
          }
        }
      }
      if isExpanded {
        ProcessListView(processes: group.processes)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
    )
    .contentShape(Rectangle())
    .onHover { isHovered = $0 }
    .onTapGesture {
      withAnimation(.snappy) { isExpanded.toggle() }
    }
  }
}
