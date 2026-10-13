import Foundation

struct ProcessSnapshot: Sendable {
  let records: [pid_t: ProcessRecord]
  /// Processes owned by root or other users. macOS doesn't let a normal app read their memory.
  let unreadableCount: Int
  let takenAt: Date
}
