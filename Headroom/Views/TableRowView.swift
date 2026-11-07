import SwiftUI

/// One line of the RAM, CPU or battery table. Detail rows carry a colour dot matching the bar and a
/// short explanation; total rows are bold and have neither.
struct TableRowView: View {
  enum DotPlacement {
    /// In its own column at the left, so every row's title is indented to make room.
    case leading
    /// Beside the value, so titles sit flush with the section headers above them.
    case beforeValue
  }

  let title: String
  var explanation: String?
  let value: String
  var color: Color?
  var isTotal = false
  var dotPlacement = DotPlacement.leading

  private static let dotColumnWidth: CGFloat = 10
  private static let titleColumnWidth: CGFloat = 104
  private static let valueColumnWidth: CGFloat = 96

  var body: some View {
    HStack(spacing: 8) {
      if dotPlacement == .leading {
        dot
          .frame(width: Self.dotColumnWidth)
      }
      Text(title)
        .fontWeight(isTotal ? .semibold : .regular)
        .frame(width: Self.titleColumnWidth, alignment: .leading)
      Text(explanation ?? "")
        .foregroundStyle(.tertiary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 6) {
        if dotPlacement == .beforeValue, color != nil {
          dot
        }
        Text(value)
          .monospacedDigit()
          .fontWeight(isTotal ? .semibold : .regular)
      }
      .frame(width: Self.valueColumnWidth, alignment: .trailing)
    }
    .font(.caption)
  }

  private var dot: some View {
    Circle()
      .fill(color ?? .clear)
      .frame(width: 8, height: 8)
  }
}
