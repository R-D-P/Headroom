import Foundation

enum GroupKind: Sendable {
  case app(pid: pid_t, bundleURL: URL?)
  case devTool(DevToolKind)
  case claudeSession
  case process
  case macOS
}
