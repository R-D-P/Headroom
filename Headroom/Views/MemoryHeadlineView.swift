import SwiftUI

/// The two numbers that matter most, side by side: what's in use, and what's free.
struct MemoryHeadlineView: View {
  let memory: SystemMemory

  var body: some View {
    HStack(alignment: .bottom) {
      HeadlineNumberView(
        caption: "In use",
        value: ByteFormatting.string(memory.usedBytes),
        tint: .primary,
        alignment: .leading
      )
      Spacer()
      HeadlineNumberView(
        caption: "Free",
        value: ByteFormatting.string(memory.freeBytes),
        tint: memory.pressure.tint,
        alignment: .trailing
      )
    }
  }
}
