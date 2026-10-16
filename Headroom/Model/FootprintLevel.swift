import SwiftUI

/// How a row's memory compares with what that kind of thing usually needs.
enum FootprintLevel {
  case light
  case typical
  case heavy

  var tint: Color {
    switch self {
    case .light: .green
    case .typical: .blue
    case .heavy: .red
    }
  }

  private static let megabyte: UInt64 = 1_048_576

  /// Apps and dev servers are expected to hold far more than a lone helper process.
  static func of(_ group: MemoryGroup) -> FootprintLevel? {
    let (lightBelow, heavyFrom): (UInt64, UInt64)
    switch group.kind {
    case .app: (lightBelow, heavyFrom) = (500 * megabyte, 2_048 * megabyte)
    case .devTool: (lightBelow, heavyFrom) = (300 * megabyte, 1_536 * megabyte)
    case .claudeSession: (lightBelow, heavyFrom) = (400 * megabyte, 1_024 * megabyte)
    case .process: (lightBelow, heavyFrom) = (100 * megabyte, 500 * megabyte)
    case .macOS: return nil
    }
    switch group.footprintBytes {
    case ..<lightBelow: return .light
    case ..<heavyFrom: return .typical
    default: return .heavy
    }
  }
}
