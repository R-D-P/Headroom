import Darwin

/// Which row a process is counted under.
enum GroupKey: Hashable {
  case app(pid_t)
  case devTool(pid_t)
  case claudeSession(pid_t)
  case process(pid_t)
  case macOS

  var id: String {
    switch self {
    case .app(let pid): "app-\(pid)"
    case .devTool(let pid): "dev-\(pid)"
    case .claudeSession(let pid): "claude-\(pid)"
    case .process(let pid): "process-\(pid)"
    case .macOS: "macos"
    }
  }
}
