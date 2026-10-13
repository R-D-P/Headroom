import Foundation
import ServiceManagement

/// `--print-groups`: prints what the panel would show as plain text, then quits.
/// Handy for checking attribution without opening the panel.
enum GroupReport {
  static func text(memory: SystemMemory?, groups: [MemoryGroup]) -> String {
    var lines = ["Open at login: \(loginStatus)"]
    if let memory {
      lines.append(
        "In use \(ByteFormatting.string(memory.usedBytes)) of \(ByteFormatting.string(memory.totalBytes)) · pressure \(memory.pressure.title)"
      )
    }
    for group in groups {
      let flag = group.isOrphaned ? " [orphaned]" : ""
      let size = ByteFormatting.string(group.footprintBytes).padding(toLength: 9, withPad: " ", startingAt: 0)
      lines.append("\(size) \(group.title)\(flag) — \(group.details.joined(separator: " · "))")
    }
    return lines.joined(separator: "\n")
  }

  private static var loginStatus: String {
    switch SMAppService.mainApp.status {
    case .enabled: "on"
    case .requiresApproval: "waiting for approval in System Settings"
    case .notRegistered: "off"
    default: "unavailable"
    }
  }
}
