/// Something plugged into one of the Mac's USB-C ports and taking power from it: a phone
/// charging, a drive, a hub with its devices.
struct PoweredAccessory: Sendable, Equatable, Identifiable {
  /// The port's number, as macOS counts them.
  let port: Int
  /// What's on the port, by the names the devices give. Empty for something that only takes
  /// power and never introduces itself, such as a charging case on a charge-only cable.
  let deviceNames: [String]
  /// What it's drawing right now, measured at the port, in watts.
  let watts: Double
  /// The most the port has agreed to supply, in watts.
  let limitWatts: Double?

  var id: Int { port }

  /// "iPhone", "Hub, Keyboard +2", or "Accessory" for one that gave no name.
  var title: String {
    guard !deviceNames.isEmpty else { return "Accessory" }
    let shown = deviceNames.prefix(2).joined(separator: ", ")
    return deviceNames.count > 2 ? "\(shown) +\(deviceNames.count - 2)" : shown
  }
}
