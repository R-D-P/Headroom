import SwiftUI

struct HeadlineNumberView: View {
  let caption: String
  let value: String
  let tint: Color
  let alignment: HorizontalAlignment

  var body: some View {
    VStack(alignment: alignment, spacing: 0) {
      Text(caption.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(size: 30, weight: .semibold).monospacedDigit())
        .foregroundStyle(tint)
    }
  }
}
