import SwiftUI

/// One line of the RAM or CPU table. Detail rows carry a colour dot matching the bar and a short
/// explanation; total rows are bold and have neither.
struct TableRowView: View {
  let title: String
  var explanation: String?
  let value: String
  var color: Color?
  var isTotal = false

  private static let dotColumnWidth: CGFloat = 10
  private static let titleColumnWidth: CGFloat = 104
  private static let valueColumnWidth: CGFloat = 96

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(color ?? .clear)
        .frame(width: 8, height: 8)
        .frame(width: Self.dotColumnWidth)
      Text(title)
        .fontWeight(isTotal ? .semibold : .regular)
        .frame(width: Self.titleColumnWidth, alignment: .leading)
      Text(explanation ?? "")
        .foregroundStyle(.tertiary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(value)
        .monospacedDigit()
        .fontWeight(isTotal ? .semibold : .regular)
        .frame(width: Self.valueColumnWidth, alignment: .trailing)
    }
    .font(.caption)
  }
}
