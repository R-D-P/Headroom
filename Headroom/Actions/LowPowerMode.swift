import Foundation

/// Switches Low Power Mode. macOS only lets an administrator change it, so the switch is made by
/// Headroom's helper, which you allow once in System Settings. When there's no helper (a
/// development build), or the helper can't be reached or fails, it falls back to the system's
/// password prompt.
enum LowPowerMode {
  static func set(_ isOn: Bool) async -> SwitchOutcome {
    switch PrivilegedHelper.prepare() {
    case .allowed:
      if await PrivilegedHelper.ask({ $0.setLowPowerMode(isOn, reply: $1) }) { return .changed }
    case .needsApproval:
      return .needsApproval
    case .unavailable:
      break
    }
    return await askWithPassword(isOn)
  }

  private static func askWithPassword(_ isOn: Bool) async -> SwitchOutcome {
    let command = "/usr/bin/pmset -a lowpowermode \(isOn ? 1 : 0)"
    let prompt = "Headroom wants to turn Low Power Mode \(isOn ? "on" : "off")."
    let script = "do shell script \"\(command)\" with prompt \"\(prompt)\" with administrator privileges"
    return await Task.detached {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
      process.arguments = ["-e", script]
      let errors = Pipe()
      process.standardError = errors
      process.standardOutput = FileHandle.nullDevice
      do { try process.run() } catch { return SwitchOutcome.failed }
      let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
      process.waitUntilExit()
      if process.terminationStatus == 0 { return .changed }
      // -128 is AppleScript's "user cancelled".
      return message.contains("-128") ? .cancelled : .failed
    }.value
  }
}
