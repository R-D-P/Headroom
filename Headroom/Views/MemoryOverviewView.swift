import SwiftUI

struct MemoryOverviewView: View {
  let memory: SystemMemory
  let isCollapsed: Bool

  var body: some View {
    if isCollapsed {
      CompactSummaryView(
        inUse: ByteFormatting.string(memory.usedBytes), freeCaption: "free",
        free: ByteFormatting.string(memory.freeBytes), freeTint: memory.pressure.tint
      ) {
        MemoryBarView(memory: memory)
      }
    } else {
      VStack(alignment: .leading, spacing: 14) {
        MemoryHeadlineView(memory: memory)
        MemoryBarView(memory: memory)
        MemoryTableView(memory: memory)
        Text(memory.pressure.advice)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }
}
