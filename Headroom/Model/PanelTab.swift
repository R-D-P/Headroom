enum PanelTab: String, CaseIterable, Identifiable {
  case memory
  case cpu
  case battery

  /// Battery only shows on Macs that have one.
  static var available: [PanelTab] {
    allCases.filter { $0 != .battery || BatteryReader.hasBattery }
  }

  var id: Self { self }

  var title: String {
    switch self {
    case .memory: "RAM"
    case .cpu: "CPU"
    case .battery: "Battery"
    }
  }
}
