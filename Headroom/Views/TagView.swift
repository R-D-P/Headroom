import SwiftUI

struct TagView: View {
  let text: String
  let tint: Color

  var body: some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(tint)
      .padding(.horizontal, 5)
      .padding(.vertical, 1)
      .background(Capsule().fill(tint.opacity(0.15)))
  }
}
