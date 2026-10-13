import AppKit

@MainActor
enum RunningAppCatalog {
  static func current() -> [pid_t: RunningAppInfo] {
    NSWorkspace.shared.runningApplications.reduce(into: [:]) { catalog, app in
      guard app.processIdentifier > 0 else { return }
      catalog[app.processIdentifier] = RunningAppInfo(
        pid: app.processIdentifier,
        name: app.localizedName ?? app.bundleURL?.deletingPathExtension().lastPathComponent
          ?? "App \(app.processIdentifier)",
        bundleIdentifier: app.bundleIdentifier,
        bundleURL: app.bundleURL,
        isRegular: app.activationPolicy == .regular
      )
    }
  }
}
