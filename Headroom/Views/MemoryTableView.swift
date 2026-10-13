import SwiftUI

/// Where every byte of RAM is, as a table: what's in use, what's free, the total, and swap.
struct MemoryTableView: View {
  let memory: SystemMemory

  var body: some View {
    VStack(spacing: 5) {
      segmentRow(.apps)
      segmentRow(.wired)
      segmentRow(.compressed)
      TableRowView(title: "In use", value: ByteFormatting.string(memory.usedBytes), isTotal: true)
      Divider()
      segmentRow(.cached)
      segmentRow(.unused)
      TableRowView(title: "Free", value: ByteFormatting.string(memory.freeBytes), isTotal: true)
      Divider()
      TableRowView(title: "Total", value: ByteFormatting.string(memory.totalBytes), isTotal: true)
      TableRowView(
        title: "Swap",
        explanation: "Memory moved out to disk",
        value: ByteFormatting.string(memory.swapUsedBytes),
        color: .orange.opacity(0.6)
      )
    }
  }

  private func segmentRow(_ segment: MemorySegment) -> TableRowView {
    TableRowView(
      title: segment.title,
      explanation: segment.explanation,
      value: ByteFormatting.string(segment.bytes(in: memory)),
      color: segment.color
    )
  }
}
