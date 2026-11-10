import Foundation
import ServiceManagement

/// Switches Low Power Mode. macOS only lets an administrator change it, so the switch is made by
/// Headroom's helper, which you allow once in System Settings. Builds that can't have a helper
/// (unsigned development builds) fall back to the system's password prompt.
enum LowPowerMode {
  enum Outcome {
    case changed
    /// The helper is waiting to be allowed in System Settings › Login Items, now open.
    case needsApproval
    case cancelled
    case failed
  }

  private static var helper: SMAppService { .daemon(plistName: HelperConstants.plistName) }

  /// Whether the switch works without asking for anything.
  static var isHelperAllowed: Bool { helper.status == .enabled }

  static func set(_ isOn: Bool) async -> Outcome {
    if helper.status != .enabled {
      try? helper.register()
    }
    switch helper.status {
    case .enabled:
      if await askHelper(isOn) { return .changed }
    case .requiresApproval:
      SMAppService.openSystemSettingsLoginItems()
      return .needsApproval
    default:
      break
    }
    return await askWithPassword(isOn)
  }

  private static func askHelper(_ isOn: Bool) async -> Bool {
    await withCheckedContinuation { continuation in
      let connection = NSXPCConnection(
        machServiceName: HelperConstants.machServiceName, options: .privileged)
      connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
      let call = HelperCall(connection: connection, continuation: continuation)
      connection.resume()
      let proxy = connection.remoteObjectProxyWithErrorHandler { _ in call.finish(false) } as? HelperProtocol
      guard let proxy else { return call.finish(false) }
      proxy.setLowPowerMode(isOn) { call.finish($0) }
      DispatchQueue.global().asyncAfter(deadline: .now() + 10) { call.finish(false) }
    }
  }

  private static func askWithPassword(_ isOn: Bool) async -> Outcome {
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
      do { try process.run() } catch { return Outcome.failed }
      let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
      process.waitUntilExit()
      if process.terminationStatus == 0 { return .changed }
      // -128 is AppleScript's "user cancelled".
      return message.contains("-128") ? .cancelled : .failed
    }.value
  }
}

/// One request to the helper. The reply, an error and the timeout race; the first one wins.
private final class HelperCall: @unchecked Sendable {
  private let lock = NSLock()
  private let connection: NSXPCConnection
  private var continuation: CheckedContinuation<Bool, Never>?

  init(connection: NSXPCConnection, continuation: CheckedContinuation<Bool, Never>) {
    self.connection = connection
    self.continuation = continuation
  }

  func finish(_ didSucceed: Bool) {
    lock.lock()
    let pending = continuation
    continuation = nil
    lock.unlock()
    guard let pending else { return }
    connection.invalidate()
    pending.resume(returning: didSucceed)
  }
}
