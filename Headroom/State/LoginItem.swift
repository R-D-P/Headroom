import Foundation
import Observation
import ServiceManagement

/// "Open at login", through the same mechanism as the Login Items list in System Settings.
@MainActor
@Observable
final class LoginItem {
  private(set) var isEnabled = false
  private(set) var needsApproval = false

  private static let autoEnabledKey = "didAutoEnableOpenAtLogin"

  init() {
    enableOnFirstInstalledLaunch()
    refresh()
  }

  func setEnabled(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      // The status read below reflects whatever actually happened.
    }
    refresh()
  }

  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }

  private func refresh() {
    let status = SMAppService.mainApp.status
    isEnabled = status == .enabled
    needsApproval = status == .requiresApproval
  }

  /// Headroom is a menu bar utility, so it opens at login unless you turn that off. Only the copy
  /// in Applications registers itself; a development build in a project folder never does.
  private func enableOnFirstInstalledLaunch() {
    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: Self.autoEnabledKey),
      Bundle.main.bundlePath.hasPrefix("/Applications/")
    else { return }
    defaults.set(true, forKey: Self.autoEnabledKey)
    try? SMAppService.mainApp.register()
  }
}
