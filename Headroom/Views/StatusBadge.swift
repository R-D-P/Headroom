import SwiftUI

struct StatusBadge: View {
  let title: String
  let tint: Color

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(tint)
        .frame(width: 7, height: 7)
      Text(title)
        .font(.caption.weight(.medium))
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(Capsule().fill(tint.opacity(0.15)))
  }
}
