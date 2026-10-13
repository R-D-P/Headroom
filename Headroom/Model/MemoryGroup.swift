/// One row in the panel: an app, a dev server, a Claude session, or macOS itself, with every
/// process that belongs to it.
struct MemoryGroup: Identifiable, Sendable {
  let id: String
  let kind: GroupKind
  let title: String
  let details: [String]
  let explanation: String?
  let footprintBytes: UInt64
  let processes: [ProcessRecord]
  let isOrphaned: Bool
  /// Set when a Claude Code session started this dev server, so stopping it asks twice.
  let startedByClaudeSession: String?
  let isSelf: Bool

  var actions: [GroupAction] {
    guard !isSelf else { return [] }
    switch kind {
    case .app(_, let bundleURL): return bundleURL == nil ? [.quit] : [.restart, .quit]
    case .devTool, .process, .claudeSession: return [.stop]
    case .macOS: return []
    }
  }

  func confirmTitle(for action: GroupAction) -> String {
    switch (action, kind) {
    case (.stop, .claudeSession): "End session?"
    case (.stop, _) where startedByClaudeSession != nil: "Claude's. Stop?"
    default: "\(action.title)?"
    }
  }
}
