enum PanelTab: String, CaseIterable, Identifiable {
  case memory
  case cpu

  var id: Self { self }

  var title: String {
    switch self {
    case .memory: "RAM"
    case .cpu: "CPU"
    }
  }
}
