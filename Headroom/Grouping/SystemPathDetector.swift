/// True for executables that ship with macOS.
enum SystemPathDetector {
  private static let systemPrefixes = ["/System/", "/usr/", "/sbin/", "/bin/", "/Library/Apple/"]

  static func isSystem(_ path: String) -> Bool {
    guard !path.hasPrefix("/usr/local/") else { return false }
    return systemPrefixes.contains { path.hasPrefix($0) }
  }
}
