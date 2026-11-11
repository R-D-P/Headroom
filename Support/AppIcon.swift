// Draws the app icon. To regenerate: swiftc Support/AppIcon.swift -o /tmp/appicon && /tmp/appicon icon.png,
// then resize into Headroom/Assets.xcassets/AppIcon.appiconset.
import AppKit

// Headroom's icon: a chip whose die is a level gauge, part full, with room to spare above.
let size: CGFloat = 1024
let output = CommandLine.arguments[1]

let rep = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
  samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
  bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let context = NSGraphicsContext.current!.cgContext

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
  CGColor(
    red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}
func gradient(_ colors: [CGColor]) -> CGGradient {
  CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
}
func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
  CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// The plate, on Apple's icon grid: 824 pt square, centred, with a soft shadow under it.
let plate = CGRect(x: 100, y: 100, width: 824, height: 824)
let platePath = rounded(plate, 186)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
context.addPath(platePath)
context.setFillColor(color(0x10131C))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(platePath)
context.clip()
context.drawLinearGradient(
  gradient([color(0x2A3350), color(0x0E111B)]),
  start: CGPoint(x: plate.midX, y: plate.maxY), end: CGPoint(x: plate.midX, y: plate.minY), options: [])
// A faint glow behind the chip.
context.drawRadialGradient(
  gradient([color(0x34D399, 0.22), color(0x34D399, 0)]),
  startCenter: CGPoint(x: 512, y: 470), startRadius: 0,
  endCenter: CGPoint(x: 512, y: 470), endRadius: 430, options: [])
context.restoreGState()

// Pins: four a side, drawn first so the body sits over their inner ends.
let body = CGRect(x: 292, y: 292, width: 440, height: 440)
let pinLength: CGFloat = 74
let pinWidth: CGFloat = 40
let pinCount = 4
let pinSpan: CGFloat = 300
context.setFillColor(color(0xC9D2E6))
for index in 0..<pinCount {
  let offset = -pinSpan / 2 + pinSpan * CGFloat(index) / CGFloat(pinCount - 1)
  let pins = [
    CGRect(x: body.midX + offset - pinWidth / 2, y: body.maxY - 20, width: pinWidth, height: pinLength + 20),
    CGRect(x: body.midX + offset - pinWidth / 2, y: body.minY - pinLength, width: pinWidth, height: pinLength + 20),
    CGRect(x: body.minX - pinLength, y: body.midY + offset - pinWidth / 2, width: pinLength + 20, height: pinWidth),
    CGRect(x: body.maxX - 20, y: body.midY + offset - pinWidth / 2, width: pinLength + 20, height: pinWidth),
  ]
  for pin in pins {
    context.addPath(rounded(pin, pinWidth / 2))
    context.fillPath()
  }
}

// The chip body.
let bodyPath = rounded(body, 84)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.45))
context.addPath(bodyPath)
context.setFillColor(color(0xF4F6FB))
context.fillPath()
context.restoreGState()
context.saveGState()
context.addPath(bodyPath)
context.clip()
context.drawLinearGradient(
  gradient([color(0xFFFFFF), color(0xD5DCEC)]),
  start: CGPoint(x: body.midX, y: body.maxY), end: CGPoint(x: body.midX, y: body.minY), options: [])
context.restoreGState()

// The die: a dark well, filled from the bottom to show what's in use, empty above it.
let die = body.insetBy(dx: 62, dy: 62)
let diePath = rounded(die, 46)
context.saveGState()
context.addPath(diePath)
context.clip()
context.setFillColor(color(0x151A27))
context.fill(die)
let level = die.height * 0.56
let fill = CGRect(x: die.minX, y: die.minY, width: die.width, height: level)
context.clip(to: fill)
context.drawLinearGradient(
  gradient([color(0x5EEAD4), color(0x22C55E)]),
  start: CGPoint(x: die.minX, y: fill.maxY), end: CGPoint(x: die.maxX, y: die.minY), options: [])
context.restoreGState()

// A highlight along the top of the fill, so it reads as a level.
context.saveGState()
context.addPath(diePath)
context.clip()
context.setFillColor(color(0xFFFFFF, 0.55))
context.fill(CGRect(x: die.minX, y: die.minY + level - 10, width: die.width, height: 10))
context.restoreGState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
