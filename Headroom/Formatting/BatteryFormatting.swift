import Foundation

enum BatteryFormatting {
  /// "28.4 W", "4.1 W".
  static func watts(_ watts: Double) -> String {
    String(format: watts >= 100 ? "%.0f W" : "%.1f W", watts)
  }

  /// "2,616 mA", "-2,616 mA".
  static func milliamps(_ milliamps: Int) -> String {
    "\(milliamps.formatted()) mA"
  }

  /// "4,367 mAh".
  static func milliampHours(_ milliampHours: Int) -> String {
    "\(milliampHours.formatted()) mAh"
  }

  /// "1:22", "0:45": hours and minutes, as the menu bar's battery shows them.
  static func duration(_ minutes: Int) -> String {
    String(format: "%d:%02d", minutes / 60, minutes % 60)
  }
}
