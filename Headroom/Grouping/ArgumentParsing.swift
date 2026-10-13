enum ArgumentParsing {
  /// The value after any of `flags`, written either as `--flag value` or `--flag=value`.
  static func value(after flags: [String], in arguments: [String]) -> String? {
    for (index, argument) in arguments.enumerated() {
      if flags.contains(argument), index + 1 < arguments.count {
        return arguments[index + 1]
      }
      if let flag = flags.first(where: { argument.hasPrefix($0 + "=") }) {
        return String(argument.dropFirst(flag.count + 1))
      }
    }
    return nil
  }

  static func port(in arguments: [String]) -> String? {
    guard let value = value(after: ["--port", "-p"], in: arguments), Int(value) != nil else {
      return nil
    }
    return value
  }
}
