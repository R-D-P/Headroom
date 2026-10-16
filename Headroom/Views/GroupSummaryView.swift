import SwiftUI

/// A row's title line, with its buttons and number on the right, and what it is underneath.
struct GroupSummaryView<Trailing: View>: View {
  let title: String
  let details: [String]
  let explanation: String?
  let isOrphaned: Bool
  let isExpanded: Bool
  @ViewBuilder let trailing: Trailing

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 6) {
        Text(title)
          .font(.system(size: 13, weight: .semibold))
          .lineLimit(1)
        if isOrphaned {
          TagView(text: "Orphaned", tint: .orange)
        }
        Image(systemName: "chevron.right")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.tertiary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
        Spacer(minLength: 8)
        trailing
          .fixedSize()
      }
      .frame(minHeight: 22)
      if !details.isEmpty {
        Text(details.joined(separator: " · "))
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      if let explanation {
        Text(explanation)
          .font(.caption)
          .foregroundStyle(.tertiary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
