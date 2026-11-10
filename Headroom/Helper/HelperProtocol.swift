import Foundation

/// The one thing the app may ask the helper to do.
@objc protocol HelperProtocol {
  func setLowPowerMode(_ isOn: Bool, reply: @escaping @Sendable (Bool) -> Void)
}

enum HelperConstants {
  static let machServiceName = "com.russellphillips.Headroom.helper"
  /// In the app at Contents/Library/LaunchDaemons.
  static let plistName = "com.russellphillips.Headroom.helper.plist"
  /// launchd sets this when it starts the app's own binary as the helper.
  static let environmentKey = "HEADROOM_HELPER"
  /// Only a Headroom signed by this Developer ID team may talk to the helper.
  static let clientRequirement =
    "anchor apple generic and identifier \"com.russellphillips.Headroom\""
    + " and certificate 1[field.1.2.840.113635.100.6.2.6] exists"
    + " and certificate leaf[field.1.2.840.113635.100.6.1.13] exists"
    + " and certificate leaf[subject.OU] = \"7EDVBP8444\""
}
