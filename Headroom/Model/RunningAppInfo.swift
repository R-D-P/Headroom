import Foundation

/// The parts of `NSRunningApplication` grouping needs, copied out so they can be passed around freely.
struct RunningAppInfo: Sendable {
  let pid: pid_t
  let name: String
  let bundleIdentifier: String?
  let bundleURL: URL?
  let isRegular: Bool

  /// Background pieces of macOS that happen to be packaged as apps (Control Centre, Siri…).
  var belongsToMacOS: Bool {
    guard !isRegular, let path = bundleURL?.path else { return false }
    return path.hasPrefix("/System/")
  }
}
