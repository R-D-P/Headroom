import SwiftUI

struct MemoryOverviewView: View {
  let memory: SystemMemory

  var body: some View {
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
