import SwiftUI

/// A row's RAM and CPU side by side as one segmented pill, with the one the list is sorted by
/// highlighted. Both always show, so the order is the only thing sorting changes.
struct MetricSegmentsView: View {
  /// Missing for macOS jobs on the CPU tab, which have no RAM figure of their own.
  let memory: String?
  var memoryTint: Color = .primary
  let cpu: String?
  let sortKey: ListSort.Key

  var body: some View {
    HStack(spacing: 0) {
      segment(memory ?? "–", tint: memory == nil ? .secondary : memoryTint, key: .memory, width: 62)
      Divider()
        .frame(height: 12)
      segment(cpu ?? "–", tint: cpu == nil ? .secondary : .primary, key: .cpu, width: 46)
    }
    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
  }

  private func segment(_ text: String, tint: Color, key: ListSort.Key, width: CGFloat) -> some View {
    Text(text)
      .font(.system(size: 12, weight: key == sortKey ? .semibold : .regular).monospacedDigit())
      .foregroundStyle(tint)
      .frame(width: width)
      .padding(.vertical, 3)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(key == sortKey ? Color.primary.opacity(0.1) : .clear)
      )
      .help(key == .memory ? "RAM" : "CPU, as a share of your whole Mac")
  }
}
