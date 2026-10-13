import Foundation

/// A readable name for one process in an expanded row: "claude 2.1.296" rather than "2.1.296",
/// "node · build/main.js" rather than "node".
enum ProcessDisplayName {
  private static let runtimes: Set<String> = ["node", "bun", "deno", "python", "python3", "ruby"]
  private static let genericScriptNames: Set<String> = ["index.js", "main.js", "cli.js", "server.js"]

  static func make(for record: ProcessRecord) -> String {
    if let version = ClaudeSessionDetector.version(of: record) {
      return "claude \(version)"
    }
    guard runtimes.contains(record.executableName), let script = scriptName(in: record.arguments) else {
      return record.name
    }
    return "\(record.executableName) · \(script)"
  }

  private static func scriptName(in arguments: [String]) -> String? {
    guard let script = arguments.dropFirst().first(where: { !$0.hasPrefix("-") }) else { return nil }
    let url = URL(fileURLWithPath: script)
    guard genericScriptNames.contains(url.lastPathComponent) else { return url.lastPathComponent }
    return "\(url.deletingLastPathComponent().lastPathComponent)/\(url.lastPathComponent)"
  }
}
