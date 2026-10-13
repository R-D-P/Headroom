import Foundation

/// One process the current user owns, with the memory macOS charges to it.
struct ProcessRecord: Sendable, Identifiable, Hashable {
  let pid: pid_t
  let parentPid: pid_t
  /// The app macOS holds responsible for this process. Helpers point at their app, and
  /// anything started from a terminal points at the terminal app.
  let responsiblePid: pid_t
  let startTime: ProcessStartTime
  let name: String
  let executablePath: String
  let arguments: [String]
  let workingDirectory: String?
  /// The same number Activity Monitor shows in its Memory column.
  let footprintBytes: UInt64

  var id: pid_t { pid }

  var executableName: String {
    guard !executablePath.isEmpty else { return name }
    return (executablePath as NSString).lastPathComponent
  }
}
