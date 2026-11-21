import Foundation

/// Eco Mode: stop charging at 60% instead of full. A battery kept around the middle wears more
/// slowly than one held near full, which matters most for a Mac that lives on its adapter.
/// Turning it off puts back the limit that was set in System Settings before, or none.
///
/// Only root can set a limit this low, so the switch is made by Headroom's helper. Builds
/// without a helper (anything but the installed, signed app) can't switch it.
enum EcoMode {
  static let percent = 60

  private static let previousPercentKey = "chargeLimitBeforeEcoMode"
  /// What System Settings can have set. Anything else saved under the key isn't put back.
  private static let restorablePercents = 80...100

  static func set(_ isOn: Bool) async -> SwitchOutcome {
    // Without knowing the limit now there's nothing safe to save, or to put back.
    guard let current = await ChargeLimitClient.readInBackground() else { return .failed }
    let defaults = UserDefaults.standard
    let target: Int
    if isOn {
      guard current.percent != percent else { return .changed }
      if restorablePercents.contains(current.percent) {
        defaults.set(current.percent, forKey: previousPercentKey)
      } else {
        defaults.removeObject(forKey: previousPercentKey)
      }
      target = percent
    } else {
      // Already off: whatever limit is set now isn't Eco Mode's to remove.
      guard current.percent == percent else {
        returnsAfterFullCharge = false
        defaults.removeObject(forKey: previousPercentKey)
        return .changed
      }
      let previous = defaults.integer(forKey: previousPercentKey)
      target = restorablePercents.contains(previous) ? previous : 100
    }
    let outcome = await apply(target)
    if case .changed = outcome {
      // Either way the switch was flipped by hand, which settles the matter.
      returnsAfterFullCharge = false
      if !isOn { defaults.removeObject(forKey: previousPercentKey) }
    }
    return outcome
  }

  /// "Charge to full": lifts the limit for one charge. Eco Mode comes back by itself once the
  /// battery reaches 100%, so forgetting to switch it on again costs nothing.
  static func chargeToFullOnce() async -> SwitchOutcome {
    let outcome = await apply(100)
    if case .changed = outcome { returnsAfterFullCharge = true }
    return outcome
  }

  /// Puts the 60% limit back, after a full charge or because the full charge was called off.
  /// What was saved to restore when Eco Mode is switched off stays as it was.
  static func resume() async -> SwitchOutcome {
    let outcome = await apply(percent)
    if case .changed = outcome { returnsAfterFullCharge = false }
    return outcome
  }

  /// Kept on disk, so the limit still comes back if Headroom is quit or the Mac restarts
  /// part-way through the charge.
  private(set) static var returnsAfterFullCharge: Bool {
    get { UserDefaults.standard.bool(forKey: returnsAfterFullChargeKey) }
    set { UserDefaults.standard.set(newValue, forKey: returnsAfterFullChargeKey) }
  }

  private static let returnsAfterFullChargeKey = "ecoModeReturnsAfterFullCharge"

  private static func apply(_ target: Int) async -> SwitchOutcome {
    switch PrivilegedHelper.prepare() {
    case .allowed:
      return await PrivilegedHelper.ask({ $0.setChargeLimit(target, reply: $1) }) ? .changed : .failed
    case .needsApproval:
      return .needsApproval
    case .unavailable:
      return .failed
    }
  }
}
