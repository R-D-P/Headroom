import SwiftUI

struct GroupIconView: View {
  let kind: GroupKind

  var body: some View {
    switch kind {
    case .app(_, .some(let bundleURL)):
      Image(nsImage: NSWorkspace.shared.icon(forFile: bundleURL.path))
        .resizable()
        .frame(width: 30, height: 30)
    case .app:
      SymbolTileView(symbolName: "app", tint: .gray)
    case .devTool(let devTool):
      SymbolTileView(symbolName: devTool.symbolName, tint: devTool.tint)
    case .claudeSession:
      SymbolTileView(symbolName: "sparkles", tint: .orange)
    case .process:
      SymbolTileView(symbolName: "gearshape", tint: .gray)
    case .macOS:
      SymbolTileView(symbolName: "apple.logo", tint: .gray)
    }
  }
}
