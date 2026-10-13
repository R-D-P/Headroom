import SwiftUI

enum MemoryPressure: Sendable, Equatable {
  case normal
  case warning
  case critical

  /// Maps `kern.memorystatus_vm_pressure_level` (1, 2 or 4).
  init(kernelLevel: Int32) {
    switch kernelLevel {
    case 4: self = .critical
    case 2: self = .warning
    default: self = .normal
    }
  }

  var title: String {
    switch self {
    case .normal: "Normal"
    case .warning: "Tight"
    case .critical: "Critical"
    }
  }

  var advice: String {
    switch self {
    case .normal: "Plenty of headroom. Nothing needs closing."
    case .warning: "Memory is getting tight. Stopping the biggest item below would help."
    case .critical: "Out of headroom. macOS is swapping to disk, so everything will feel slow."
    }
  }

  var tint: Color {
    switch self {
    case .normal: .green
    case .warning: .yellow
    case .critical: .red
    }
  }
}
