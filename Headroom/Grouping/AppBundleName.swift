/// "Wispr Flow" from "/Applications/Wispr Flow.app/Contents/MacOS/Wispr Flow".
enum AppBundleName {
  static func from(path: String) -> String? {
    path.split(separator: "/")
      .first { $0.hasSuffix(".app") }
      .map { String($0.dropLast(".app".count)) }
  }
}
