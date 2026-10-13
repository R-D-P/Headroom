import Foundation

enum PercentFormatting {
  /// "42%", "3%", "0.4%": small values keep a decimal so a quiet process doesn't read as 0%.
  static func string(_ fraction: Double) -> String {
    let percent = fraction * 100
    guard percent < 1 else { return String(format: "%.0f%%", percent) }
    return String(format: "%.1f%%", percent)
  }
}
