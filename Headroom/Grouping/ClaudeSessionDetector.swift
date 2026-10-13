/// Recognises the Claude Code CLI, both the native install (`~/.local/share/claude/versions/x.y.z`)
/// and the older npm install that runs under node.
enum ClaudeSessionDetector {
  private static let versionsDirectory = "/claude/versions/"

  static func isSession(_ record: ProcessRecord) -> Bool {
    if record.executablePath.contains(versionsDirectory) || record.executableName == "claude" {
      return true
    }
    guard record.executableName == "node", record.arguments.count > 1 else { return false }
    return record.arguments[1].hasSuffix("/claude")
  }

  static func version(of record: ProcessRecord) -> String? {
    guard record.executablePath.contains(versionsDirectory) else { return nil }
    return record.executableName
  }

  static func shortSessionId(of record: ProcessRecord) -> String? {
    ArgumentParsing.value(after: ["--session-id", "--resume", "-r"], in: record.arguments)
      .map { String($0.prefix(8)) }
  }

  static func label(for record: ProcessRecord) -> String {
    guard let sessionId = shortSessionId(of: record) else { return "Claude session (pid \(record.pid))" }
    return "Claude session \(sessionId)"
  }
}
