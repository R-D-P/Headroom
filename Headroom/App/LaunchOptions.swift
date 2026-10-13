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

  /// `--stop "<row title>"`: runs the Stop action on the first matching row, prints the result,
  /// then quits. The same code path as the Stop button, usable from a script.
  static var groupTitleToStop: String? {
    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--stop"), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
  }
}
