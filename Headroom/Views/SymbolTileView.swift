import SwiftUI

struct SymbolTileView: View {
  let symbolName: String
  let tint: Color

  var body: some View {
    Image(systemName: symbolName)
      .font(.system(size: 14, weight: .medium))
      .foregroundStyle(tint)
      .frame(width: 30, height: 30)
      .background(RoundedRectangle(cornerRadius: 7).fill(tint.opacity(0.15)))
  }
}
