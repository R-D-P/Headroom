import AppKit
import SwiftUI

/// The chip icon, plain while RAM, CPU and battery are all fine. It turns yellow when one needs
/// a look, and red with the reading beside it when one is in trouble.
struct MenuBarLabel: View {
  let status: MenuBarStatus
  let pulseOpacity: Double

  private static let symbolName = "memorychip"
  /// A fifth larger than the 13 pt the menu bar gives a symbol by default.
  private static let symbolPointSize: CGFloat = 13 * 1.2

  var body: some View {
    switch status.level {
    case .normal:
      Image(nsImage: Self.image(text: nil, color: nil))
    case .warning:
      Image(nsImage: Self.image(text: nil, color: .systemYellow))
    case .critical:
      Image(
        nsImage: Self.image(
          text: status.criticalReadings.joined(separator: "  "),
          color: .systemRed.withAlphaComponent(status.pulses ? pulseOpacity : 1)))
    }
  }

  /// The menu bar draws SwiftUI symbols and text in its own colour whatever is asked for, so
  /// anything coloured is drawn as a picture instead.
  /// With no colour the picture is a template, which the menu bar tints to suit itself.
  private static func image(text: String?, color: NSColor?) -> NSImage {
    let fontSize = NSFont.menuBarFont(ofSize: 0).pointSize
    let configuration = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
    let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Headroom")?
      .withSymbolConfiguration(
        color.map { configuration.applying(.init(paletteColors: [$0])) } ?? configuration)
    let label = text.flatMap { $0.isEmpty ? nil : $0 }.map {
      NSAttributedString(
        string: $0,
        attributes: [
          .font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold),
          .foregroundColor: color ?? .labelColor,
        ])
    }

    let symbolSize = symbol?.size ?? .zero
    let labelSize = label?.size() ?? .zero
    let gap: CGFloat = label == nil ? 0 : 5
    let size = NSSize(
      width: ceil(symbolSize.width + gap + labelSize.width),
      height: ceil(max(symbolSize.height, labelSize.height)))
    let image = NSImage(size: size, flipped: false) { _ in
      symbol?.draw(
        in: NSRect(origin: NSPoint(x: 0, y: (size.height - symbolSize.height) / 2), size: symbolSize))
      label?.draw(at: NSPoint(x: symbolSize.width + gap, y: (size.height - labelSize.height) / 2))
      return true
    }
    image.isTemplate = color == nil
    return image
  }
}
