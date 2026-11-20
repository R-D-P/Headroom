import AppKit

/// Quits and relaunches regular apps the way the Dock does, so they get to save their state.
@MainActor
enum AppLifecycle {
  private static let quitPollAttempts = 40
  private static let pollInterval = Duration.milliseconds(250)

  /// `startTime` is the app's as the row showed it. A pid that now belongs to something else
  /// means the app has already gone, and whatever took its number is left alone.
  static func quit(pid: pid_t, startTime: ProcessStartTime?) async -> Bool {
    guard let app = NSRunningApplication(processIdentifier: pid) else { return true }
    if let startTime, ProcessSyscalls.bsdInfo(of: pid)?.startTime != startTime { return true }
    guard app.terminate() else { return false }
    for _ in 0..<quitPollAttempts {
      if app.isTerminated {
        return true
      }
      try? await Task.sleep(for: pollInterval)
    }
    return app.isTerminated
  }

  static func restart(pid: pid_t, startTime: ProcessStartTime?, bundleURL: URL) async -> Bool {
    guard await quit(pid: pid, startTime: startTime) else { return false }
    NSWorkspace.shared.openApplication(
      at: bundleURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    return true
  }
}
