import SwiftUI

/// Whether macOS is slowing the chip down to keep it cool, the other reason a Mac feels slow.
enum ThermalState: Sendable, Equatable {
  case nominal
  case fair
  case serious
  case critical

  init(_ state: ProcessInfo.ThermalState) {
    switch state {
    case .fair: self = .fair
    case .serious: self = .serious
    case .critical: self = .critical
    default: self = .nominal
    }
  }

  var title: String {
    switch self {
    case .nominal: "Cool"
    case .fair: "Warm"
    case .serious: "Hot, slowing down"
    case .critical: "Very hot, slowing down"
    }
  }

  var tint: Color {
    switch self {
    case .nominal: .green
    case .fair: .yellow
    case .serious: .orange
    case .critical: .red
    }
  }
}
