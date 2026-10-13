import Foundation

/// A plain-English line on why an app uses the memory it does.
enum AppExplanation {
  private static let terminals: Set<String> = [
    "com.cmuxterm.app", "com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty",
    "dev.warp.Warp-Stable", "net.kovidgoyal.kitty", "org.alacritty", "com.github.wez.wezterm",
  ]
  private static let browsers: Set<String> = [
    "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac", "company.thebrowser.Browser",
    "com.vivaldi.Vivaldi", "com.apple.Safari", "org.mozilla.firefox",
  ]

  static func text(for app: RunningAppInfo) -> String? {
    let identifier = app.bundleIdentifier ?? ""
    if terminals.contains(identifier) {
      return "Terminal: the app and the shells in its tabs. Claude sessions and dev servers started here have their own rows."
    }
    if browsers.contains(identifier) {
      return "Browser: every tab, extension and helper runs as its own process."
    }
    if isElectron(app.bundleURL) {
      return "Electron app: ships its own copy of Chrome, so it carries a browser's overhead."
    }
    return nil
  }

  private static func isElectron(_ bundleURL: URL?) -> Bool {
    guard let bundleURL else { return false }
    let framework = bundleURL.appendingPathComponent("Contents/Frameworks/Electron Framework.framework")
    return FileManager.default.fileExists(atPath: framework.path)
  }
}
