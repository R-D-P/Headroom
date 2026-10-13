import AppKit

/// Quits and relaunches regular apps the way the Dock does, so they get to save their state.
@MainActor
enum AppLifecycle {
  private static let quitPollAttempts = 40
  private static let pollInterval = Duration.milliseconds(250)

  static func quit(pid: pid_t) async -> Bool {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return true }
    guard app.terminate() else { return false }
    for _ in 0..<quitPollAttempts {
      if app.isTerminated {
        return true
      }
      try? await Task.sleep(for: pollInterval)
    }
    return app.isTerminated
  }

  static func restart(pid: pid_t, bundleURL: URL) async -> Bool {
    guard await quit(pid: pid) else { return false }
    NSWorkspace.shared.openApplication(
      at: bundleURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    return true
  }
}
