import Foundation
import ServiceManagement

/// How flipping one of the Battery tab's switches went.
enum SwitchOutcome {
  case changed
  /// The helper is waiting to be allowed in System Settings › Login Items, now open.
  case needsApproval
  case cancelled
  case failed
}

/// The app's side of the helper: getting it allowed, then asking it for something.
enum PrivilegedHelper {
  enum Availability {
    case allowed
    /// Waiting to be allowed in System Settings › Login Items, which this has just opened.
    case needsApproval
    /// Builds that can't have a helper: anything but the installed, signed app.
    case unavailable
  }

  private static var service: SMAppService { .daemon(plistName: HelperConstants.plistName) }

  /// Only the copy in Applications gets a helper. One registered from a build folder would have
  /// launchd running whatever is later built there as root.
  static let isInstalled = Bundle.main.bundlePath.hasPrefix("/Applications/")

  /// Whether the switches work without asking for anything.
  static var isAllowed: Bool { isInstalled && service.status == .enabled }

  static func prepare() -> Availability {
    guard isInstalled else { return .unavailable }
    if service.status != .enabled {
      try? service.register()
    }
    switch service.status {
    case .enabled:
      return .allowed
    case .requiresApproval:
      SMAppService.openSystemSettingsLoginItems()
      return .needsApproval
    default:
      return .unavailable
    }
  }

  /// Makes one request. False when the helper said no, couldn't be reached or took too long.
  static func ask(_ request: (HelperProtocol, @escaping @Sendable (Bool) -> Void) -> Void) async -> Bool {
    await withCheckedContinuation { continuation in
      let connection = NSXPCConnection(
        machServiceName: HelperConstants.machServiceName, options: .privileged)
      connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
      let call = HelperCall(connection: connection, continuation: continuation)
      connection.resume()
      let proxy = connection.remoteObjectProxyWithErrorHandler { _ in call.finish(false) } as? HelperProtocol
      guard let proxy else { return call.finish(false) }
      request(proxy) { call.finish($0) }
      DispatchQueue.global().asyncAfter(deadline: .now() + 10) { call.finish(false) }
    }
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
