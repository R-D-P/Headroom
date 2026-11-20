import Foundation

/// Headroom's own binary, started by launchd as root when the app asks for something macOS only
/// lets an administrator do: switching Low Power Mode, or setting where charging stops. It does
/// what it was asked and quits once it has been idle for a few seconds.
final class HelperDaemon: NSObject, NSXPCListenerDelegate, HelperProtocol {
  /// launchd marks the helper with an environment variable. Root is checked too, so the variable
  /// turning up in someone's own environment doesn't stop the app from opening.
  static var isHelperProcess: Bool {
    ProcessInfo.processInfo.environment[HelperConstants.environmentKey] == "1" && geteuid() == 0
  }

  /// Long enough for the reply to reach the app; launchd starts a fresh helper next time.
  private static let lingerSeconds = 5.0

  private let idleExit = IdleExit()

  static func run() -> Never {
    let daemon = HelperDaemon()
    let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
    listener.delegate = daemon
    listener.resume()
    // Started but never asked anything: don't sit around as root.
    daemon.idleExit.exit(afterIdleFor: 30)
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
    idleExit.begin()
    defer { idleExit.end(thenExitAfterIdleFor: Self.lingerSeconds) }
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
  }

  func setChargeLimit(_ percent: Int, reply: @escaping @Sendable (Bool) -> Void) {
    idleExit.begin()
    defer { idleExit.end(thenExitAfterIdleFor: Self.lingerSeconds) }
    reply(ChargeLimitClient.apply(percent))
  }
}

/// Quits the helper once nothing has been asked of it for a while. A request that arrives or is
/// still running when a timer fires cancels that timer, so no request is cut off part-way.
private final class IdleExit: @unchecked Sendable {
  private let lock = NSLock()
  private var activeRequests = 0
  /// Goes up with every request, so a timer can tell whether anything happened since it was set.
  private var requestCount = 0

  func begin() {
    lock.withLock {
      activeRequests += 1
      requestCount += 1
    }
  }

  func end(thenExitAfterIdleFor seconds: Double) {
    lock.withLock { activeRequests -= 1 }
    exit(afterIdleFor: seconds)
  }

  func exit(afterIdleFor seconds: Double) {
    let countWhenSet = lock.withLock { requestCount }
    DispatchQueue.global().asyncAfter(deadline: .now() + seconds) { [self] in
      let isIdle = lock.withLock { activeRequests == 0 && requestCount == countWhenSet }
      if isIdle { Darwin.exit(0) }
    }
  }
}
