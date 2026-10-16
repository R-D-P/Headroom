import SwiftUI

struct CPUGroupRowView: View {
  let group: CPUGroup
  let sortKey: ListSort.Key
  let isBusy: Bool
  let onAction: (GroupAction, MemoryGroup) -> Void

  @State private var isExpanded = false
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 10) {
        icon
        GroupSummaryView(
          title: group.title, details: group.details, explanation: group.explanation,
          isOrphaned: group.memoryGroup?.isOrphaned ?? false, isExpanded: isExpanded
        ) {
          HStack(spacing: 8) {
            if let memoryGroup = group.memoryGroup {
              ActionSegmentsView(group: memoryGroup, isBusy: isBusy) { action in
                onAction(action, memoryGroup)
              }
            }
            MetricSegmentsView(
              memory: group.memoryGroup.map { ByteFormatting.string($0.footprintBytes) },
              memoryTint: group.memoryGroup.flatMap(FootprintLevel.of)?.tint ?? .primary,
              cpu: PercentFormatting.string(group.share),
              sortKey: sortKey)
          }
        }
      }
      if isExpanded {
        CPUProcessListView(processes: group.processes)
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

  @ViewBuilder
  private var icon: some View {
    if let memoryGroup = group.memoryGroup {
      GroupIconView(kind: memoryGroup.kind)
    } else {
      let subsystem = group.subsystem ?? .other
      SymbolTileView(symbolName: subsystem.symbolName, tint: subsystem.tint)
    }
  }
}
