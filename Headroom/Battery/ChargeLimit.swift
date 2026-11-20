import Foundation
import ObjectiveC
import notify

/// Where macOS stops charging. 100 means no limit.
struct ChargeLimit: Sendable, Equatable {
  let percent: Int

  /// Nil when the battery is free to charge to full.
  var activePercent: Int? { percent < 100 ? percent : nil }
}

/// Talks to PowerUIAgent, the part of macOS behind the Charge Limit slider in System Settings.
/// The limit is enforced by macOS itself, so it holds while Headroom isn't running and while
/// the Mac sleeps.
///
/// The framework is private, so it's loaded at run time and called by name. Anyone may read the
/// limit. The slider's own setter refuses anything under 80%; lower targets go into the agent's
/// preferences, which only root can write. Newer Macs no longer let even root pause charging
/// directly, which is why this goes through the agent. The same route is used by the open-source
/// `batt` (charlie0129/batt, pkg/powerui).
enum ChargeLimitClient {
  /// The only targets the helper will set: Eco Mode's, and the ones System Settings offers.
  /// 100 lifts the limit.
  static func accepts(_ percent: Int) -> Bool {
    percent == EcoMode.percent || (80...100).contains(percent)
  }

  private static let frameworkPath = "/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/PowerUI"
  private static var preferences: CFString { "com.apple.smartcharging.topoffprotection" as CFString }
  private static var enabledKey: CFString { "MCLFeatureState" as CFString }
  private static var percentKey: CFString { "mclLimitValue" as CFString }
  private static let preferencesChanged = "com.apple.smartcharging.defaultschanged"

  private typealias ErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>
  private typealias IsSupported = @convention(c) (AnyObject, Selector) -> Bool
  private typealias GetPercent = @convention(c) (AnyObject, Selector, ErrorPointer) -> UInt8
  private typealias GetEnabled = @convention(c) (AnyObject, Selector, ErrorPointer) -> UInt64
  private typealias Switch = @convention(c) (AnyObject, Selector, ErrorPointer) -> Bool

  private static let isSupportedSelector = NSSelectorFromString("isMCLSupported")
  private static let percentSelector = NSSelectorFromString("getMCLLimitWithError:")
  private static let enabledSelector = NSSelectorFromString("isMCLCurrentlyEnabled:")
  private static let enableSelector = NSSelectorFromString("enableMCL:")
  private static let disableSelector = NSSelectorFromString("disableMCL:")

  /// What each call takes and returns, as the Objective-C runtime describes it. The calls are
  /// made through bare function pointers, so a method that kept its name but changed shape in
  /// some later macOS would be called wrongly. Anything but an exact match counts as unsupported.
  private static let expectedEncodings: [(Selector, String)] = [
    (isSupportedSelector, "B16@0:8"),
    (percentSelector, "C24@0:8^@16"),
    (enabledSelector, "Q24@0:8^@16"),
    (enableSelector, "B24@0:8^@16"),
    (disableSelector, "B24@0:8^@16"),
  ]

  /// Made once. Nil when this macOS doesn't have the calls used here, exactly as expected.
  nonisolated(unsafe) private static let client: NSObject? = {
    guard dlopen(frameworkPath, RTLD_NOW) != nil,
      let type = NSClassFromString("PowerUISmartChargeClient") as? NSObject.Type,
      let allocated = type.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() as? NSObject,
      allocated.responds(to: NSSelectorFromString("initWithClientName:")),
      let client = allocated.perform(NSSelectorFromString("initWithClientName:"), with: "Headroom")?
        .takeUnretainedValue() as? NSObject
    else { return nil }
    let matches = expectedEncodings.allSatisfy { selector, expected in
      guard let method = class_getInstanceMethod(type, selector),
        let encoding = method_getTypeEncoding(method)
      else { return false }
      return String(cString: encoding) == expected
    }
    return matches ? client : nil
  }()

  /// One call into the client at a time: it's shared, and reads come from several threads.
  private static let lock = NSLock()

  /// Whether this Mac can be given a limit below what System Settings offers. The first use
  /// loads the framework and asks the agent, so keep it off the main thread.
  static let isSupported: Bool = {
    guard let client else { return false }
    return lock.withLock {
      unsafeBitCast(client.method(for: isSupportedSelector), to: IsSupported.self)(
        client, isSupportedSelector)
    }
  }()

  /// Asks the agent, which normally answers in a few milliseconds. Not for the main thread.
  static func read() -> ChargeLimit? {
    guard isSupported, let isEnabled = isEnabled() else { return nil }
    guard isEnabled else { return ChargeLimit(percent: 100) }
    return limitPercent().map(ChargeLimit.init)
  }

  /// `read()` for the app: off the main thread, and nil rather than a wait if the agent hangs.
  static func readInBackground() async -> ChargeLimit? {
    guard pendingRead.begin() else { return nil }
    return await withCheckedContinuation { continuation in
      let result = FirstResult(continuation)
      DispatchQueue.global().async {
        let limit = read()
        pendingRead.end()
        result.finish(limit)
      }
      DispatchQueue.global().asyncAfter(deadline: .now() + 3) { result.finish(nil) }
    }
  }

  /// Sets the limit, or lifts it at 100. Only works as root, so only the helper calls it.
  /// On failure the limit is put back as it was found.
  static func apply(_ percent: Int) -> Bool {
    guard isSupported, accepts(percent), let wasEnabled = isEnabled() else { return false }
    if percent == 100 { return wasEnabled ? lift() : true }
    let previous = wasEnabled ? limitPercent() : nil
    if previous == percent { return true }
    if !wasEnabled, !send(enableSelector) { return false }
    if write(percent) { return true }
    // Switching the limit on leaves macOS's own 80% in force, which Headroom shows nowhere.
    if let previous { _ = write(previous) } else if !wasEnabled { _ = lift() }
    return false
  }

  /// Writes the target until the agent reports it back, twice running. Switching the limit on
  /// makes the agent save its own 80% a moment later, which can land on top of the target.
  private static func write(_ percent: Int) -> Bool {
    for _ in 0..<8 {
      CFPreferencesSetValue(enabledKey, 1 as CFNumber, preferences, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
      CFPreferencesSetValue(
        percentKey, percent as CFNumber, preferences, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
      guard CFPreferencesSynchronize(preferences, kCFPreferencesCurrentUser, kCFPreferencesAnyHost),
        notify_post(preferencesChanged) == NOTIFY_STATUS_OK
      else { return false }
      Thread.sleep(forTimeInterval: 0.25)
      guard limitPercent() == percent else { continue }
      Thread.sleep(forTimeInterval: 0.5)
      if limitPercent() == percent { return true }
    }
    return false
  }

  /// Switches the limit off, and waits to see that the agent agrees.
  private static func lift() -> Bool {
    guard send(disableSelector) else { return false }
    for _ in 0..<8 {
      if isEnabled() == false { return true }
      Thread.sleep(forTimeInterval: 0.25)
    }
    return false
  }

  private static func isEnabled() -> Bool? {
    guard let client else { return nil }
    var error: NSError?
    let state = lock.withLock {
      unsafeBitCast(client.method(for: enabledSelector), to: GetEnabled.self)(client, enabledSelector, &error)
    }
    return error == nil ? state != 0 : nil
  }

  private static func limitPercent() -> Int? {
    guard let client else { return nil }
    var error: NSError?
    let percent = lock.withLock {
      unsafeBitCast(client.method(for: percentSelector), to: GetPercent.self)(client, percentSelector, &error)
    }
    return error == nil ? Int(percent) : nil
  }

  private static func send(_ selector: Selector) -> Bool {
    guard let client else { return false }
    var error: NSError?
    let didSucceed = lock.withLock {
      unsafeBitCast(client.method(for: selector), to: Switch.self)(client, selector, &error)
    }
    return didSucceed && error == nil
  }

  private static let pendingRead = PendingRead()
}

/// Keeps background reads from piling up behind an agent that has stopped answering.
private final class PendingRead: @unchecked Sendable {
  private let lock = NSLock()
  private var isPending = false

  /// False when a read is still out.
  func begin() -> Bool {
    lock.withLock {
      guard !isPending else { return false }
      isPending = true
      return true
    }
  }

  func end() {
    lock.withLock { isPending = false }
  }
}

/// The answer and the timeout race; the first one wins.
private final class FirstResult: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<ChargeLimit?, Never>?

  init(_ continuation: CheckedContinuation<ChargeLimit?, Never>) {
    self.continuation = continuation
  }

  func finish(_ limit: ChargeLimit?) {
    let pending = lock.withLock {
      let pending = continuation
      continuation = nil
      return pending
    }
    pending?.resume(returning: limit)
  }
}
