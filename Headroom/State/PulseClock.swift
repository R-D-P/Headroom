import Foundation
import Observation

/// Drives the menu bar's low-battery pulse. The menu bar doesn't run SwiftUI animations, so this
/// steps an opacity by hand, and only while switched on.
@MainActor
@Observable
final class PulseClock {
  /// Fades between dim and full, about once a second.
  private(set) var opacity = 1.0

  @ObservationIgnored private var task: Task<Void, Never>?

  private static let period = 1.2
  private static let framesPerSecond = 10.0
  private static let dimmest = 0.3

  func setActive(_ isActive: Bool) {
    guard isActive != (task != nil) else { return }
    task?.cancel()
    task = nil
    opacity = 1
    guard isActive else { return }
    task = Task { [weak self] in
      var elapsed = 0.0
      while !Task.isCancelled {
        let wave = (1 + cos(2 * .pi * elapsed / Self.period)) / 2
        self?.opacity = Self.dimmest + (1 - Self.dimmest) * wave
        try? await Task.sleep(for: .seconds(1 / Self.framesPerSecond))
        elapsed += 1 / Self.framesPerSecond
      }
    }
  }
}
