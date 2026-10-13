/// Decides whether a process is a dev server or tool that deserves its own row.
/// Rules are checked in order, so specific ones (mongod) come before broad ones (anything Meteor).
enum DevToolClassifier {
  private static let shells: Set<String> = ["zsh", "bash", "sh", "fish", "dash"]
  private static let scriptRuntimes: Set<String> = ["node", "bun", "deno", "python", "python3", "ruby"]

  static func kind(of record: ProcessRecord) -> DevToolKind? {
    // A shell running `-c "npm run storybook"` mentions the tool but isn't it; its child is.
    guard !shells.contains(record.executableName) else { return nil }
    return rules.first { $0.matches(record) }?.kind
  }

  private static let rules: [DevToolRule] = [
    DevToolRule(kind: .mongo) { $0.executableName == "mongod" },
    DevToolRule(kind: .postgres) { $0.executableName == "postgres" },
    DevToolRule(kind: .redis) { $0.executableName == "redis-server" },
    DevToolRule(kind: .watchman) { $0.executableName == "watchman" },
    DevToolRule(kind: .meteor) { record in
      record.executablePath.contains("/.meteor/")
        || record.arguments.contains { $0 == "meteor" || $0.hasSuffix("/meteor") }
    },
    DevToolRule(kind: .storybook) { commandLine(of: $0).contains("storybook") },
    DevToolRule(kind: .playwright) { record in
      record.executablePath.contains("ms-playwright") || commandLine(of: record).contains("playwright")
    },
    DevToolRule(kind: .nextjs) { record in
      record.executableName == "next-server"
        || (record.arguments.contains { $0.hasSuffix("/next") } && record.arguments.contains("dev"))
    },
    DevToolRule(kind: .vite) { record in
      record.arguments.contains { $0 == "vite" || $0.hasSuffix("/vite") || $0.hasSuffix("/vite.js") }
    },
    DevToolRule(kind: .jestWatch) { record in
      commandLine(of: record).contains("jest") && hasWatchFlag(record)
    },
    DevToolRule(kind: .typescriptWatch) { record in
      let command = commandLine(of: record)
      return (command.contains("tsc") || command.contains("tsgo")) && hasWatchFlag(record)
    },
    DevToolRule(kind: .bundler) { record in
      let command = commandLine(of: record)
      let isBundler = command.contains("rspack") || command.contains("webpack")
      return isBundler && (record.arguments.contains("serve") || hasWatchFlag(record))
    },
    DevToolRule(kind: .nodemon) { commandLine(of: $0).contains("nodemon") },
    DevToolRule(kind: .script) { record in
      record.parentPid == 1 && scriptRuntimes.contains(record.executableName)
    },
  ]

  private static func commandLine(of record: ProcessRecord) -> String {
    record.arguments.joined(separator: " ")
  }

  private static func hasWatchFlag(_ record: ProcessRecord) -> Bool {
    record.arguments.contains { $0 == "--watch" || $0 == "-w" || $0 == "--watchAll" }
  }
}
