import Foundation

/// `--open-window` opens the panel as a regular window at launch, which makes it easy to
/// screenshot and debug without clicking the menu bar icon.
enum LaunchOptions {
  static var opensWindowAtLaunch: Bool {
    ProcessInfo.processInfo.arguments.contains("--open-window")
  }

  static var printsGroupsAndExits: Bool {
    ProcessInfo.processInfo.arguments.contains("--print-groups")
  }

  /// `--battery-charge 8`: pretends the battery is unplugged and at that percent, to see the
  /// low-battery menu bar icon without running the battery down.
  static var simulatedCharge: Double? {
    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--battery-charge"), index + 1 < arguments.count,
      let percent = Double(arguments[index + 1])
    else { return nil }
    return min(1, max(0, percent / 100))
  }

  /// `--low-power on` or `--low-power off`: flips Low Power Mode the way the switch does, prints
  /// the result, then quits.
  static var lowPowerModeToSet: Bool? {
    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--low-power"), index + 1 < arguments.count else { return nil }
    switch arguments[index + 1] {
    case "on": return true
    case "off": return false
    default: return nil
    }
  }

  /// `--stop "<row title>"`: runs the Stop action on the first matching row, prints the result,
  /// then quits. The same code path as the Stop button, usable from a script.
  static var groupTitleToStop: String? {
    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--stop"), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
  }
}
