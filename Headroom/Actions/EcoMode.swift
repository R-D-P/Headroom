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
        defaults.removeObject(forKey: previousPercentKey)
        return .changed
      }
      let previous = defaults.integer(forKey: previousPercentKey)
      target = restorablePercents.contains(previous) ? previous : 100
    }
    switch PrivilegedHelper.prepare() {
    case .allowed:
      guard await PrivilegedHelper.ask({ $0.setChargeLimit(target, reply: $1) }) else { return .failed }
      if !isOn { defaults.removeObject(forKey: previousPercentKey) }
      return .changed
    case .needsApproval:
      return .needsApproval
    case .unavailable:
      return .failed
    }
  }
}
