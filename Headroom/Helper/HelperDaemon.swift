import Foundation

/// Headroom's own binary, started by launchd as root when the app asks for Low Power Mode to be
/// switched, which macOS only lets an administrator do. It does that one thing and quits.
final class HelperDaemon: NSObject, NSXPCListenerDelegate, HelperProtocol {
  static var isHelperProcess: Bool {
    ProcessInfo.processInfo.environment[HelperConstants.environmentKey] == "1"
  }

  /// Long enough for the reply to reach the app; launchd starts a fresh helper next time.
  private static let lingerSeconds = 5.0

  static func run() -> Never {
    let daemon = HelperDaemon()
    let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
    listener.delegate = daemon
    listener.resume()
    // Started but never asked anything: don't sit around as root.
    quitSoon(after: 30)
    withExtendedLifetime((daemon, listener)) { dispatchMain() }
  }

  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
    connection.setCodeSigningRequirement(HelperConstants.clientRequirement)
    connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
    connection.exportedObject = self
    connection.resume()
    return true
  }

  func setLowPowerMode(_ isOn: Bool, reply: @escaping @Sendable (Bool) -> Void) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["-a", "lowpowermode", isOn ? "1" : "0"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    var didSucceed = false
    if (try? process.run()) != nil {
      process.waitUntilExit()
      didSucceed = process.terminationStatus == 0
    }
    reply(didSucceed)
    Self.quitSoon(after: Self.lingerSeconds)
  }

  private static func quitSoon(after seconds: Double) {
    DispatchQueue.global().asyncAfter(deadline: .now() + seconds) { exit(0) }
  }
}
