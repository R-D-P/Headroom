import Foundation

/// Decides whether a process is a dev server or tool that deserves its own row.
/// Rules are checked in order, so specific ones (mongod) come before broad ones (anything Meteor).
///
/// Rules look at what the process is running, never at the files or words it was handed:
/// `vim playwright.config.ts` is an editor, not Playwright, and its row's Stop would kill it.
enum DevToolClassifier {
  private static let shells: Set<String> = ["zsh", "bash", "sh", "fish", "dash"]
  private static let scriptRuntimes: Set<String> = ["node", "bun", "deno", "python", "python3", "ruby"]
  /// Programs that run another program named in their arguments, and the words that go between
  /// (`npm run storybook`, `npx playwright test`, `dotenvx run -- meteor`).
  private static let launchers: Set<String> = scriptRuntimes.union([
    "npm", "npm-cli", "npx", "npx-cli", "pnpm", "pnpx", "yarn", "yarnpkg", "bunx", "corepack",
    "tsx", "ts-node", "dotenvx", "dotenv", "cross-env", "env", "run", "exec", "dlx", "x",
  ])
  private static let scriptExtensions: Set<String> = ["js", "cjs", "mjs", "ts"]
  private static let maximumLaunchDepth = 5

  static func kind(of record: ProcessRecord) -> DevToolKind? {
    // A shell running `-c "npm run storybook"` mentions the tool but isn't it; its child is.
    guard !shells.contains(record.executableName) else { return nil }
    let program = Program(record: record, names: programNames(of: record))
    return rules.first { $0.matches(program) }?.kind
  }

  /// The executable, the name it was started under, and, when that's a launcher, what it
  /// launches: for `node /usr/local/bin/npm run storybook`, node, then npm, run and storybook.
  private static func programNames(of record: ProcessRecord) -> [String] {
    var names = [record.executablePath]
    guard let invokedAs = record.arguments.first else { return names }
    names.append(invokedAs)
    var launcher = record.executableName
    for word in record.arguments.dropFirst() where !word.hasPrefix("-") {
      guard launchers.contains(launcher), names.count < maximumLaunchDepth + 2 else { break }
      names.append(word)
      launcher = commandName(of: word)
    }
    return names
  }

  /// "/usr/local/lib/node_modules/npm/bin/npm-cli.js" is "npm-cli".
  private static func commandName(of word: String) -> String {
    let file = (word as NSString).lastPathComponent
    let fileExtension = (file as NSString).pathExtension
    return scriptExtensions.contains(fileExtension) ? (file as NSString).deletingPathExtension : file
  }

  private static let rules: [DevToolRule] = [
    DevToolRule(kind: .mongo) { $0.record.executableName == "mongod" },
    DevToolRule(kind: .postgres) { $0.record.executableName == "postgres" },
    DevToolRule(kind: .redis) { $0.record.executableName == "redis-server" },
    DevToolRule(kind: .watchman) { $0.record.executableName == "watchman" },
    DevToolRule(kind: .meteor) { program in
      program.record.executablePath.contains("/.meteor/") || program.runs("meteor")
    },
    DevToolRule(kind: .storybook) { $0.mentions("storybook") },
    DevToolRule(kind: .playwright) { $0.mentions("playwright") },
    DevToolRule(kind: .nextjs) { program in
      program.record.executableName == "next-server"
        || (program.runs("next") && program.record.arguments.contains("dev"))
    },
    DevToolRule(kind: .vite) { $0.runs("vite") },
    DevToolRule(kind: .jestWatch) { $0.mentions("jest") && hasWatchFlag($0.record) },
    DevToolRule(kind: .typescriptWatch) { program in
      (program.runs("tsc") || program.runs("tsgo")) && hasWatchFlag(program.record)
    },
    DevToolRule(kind: .bundler) { program in
      let isBundler = program.mentions("rspack") || program.mentions("webpack")
      return isBundler && (program.record.arguments.contains("serve") || hasWatchFlag(program.record))
    },
    DevToolRule(kind: .nodemon) { $0.mentions("nodemon") },
    DevToolRule(kind: .script) { program in
      program.record.parentPid == 1 && scriptRuntimes.contains(program.record.executableName)
    },
  ]

  private static func hasWatchFlag(_ record: ProcessRecord) -> Bool {
    record.arguments.contains { $0 == "--watch" || $0 == "-w" || $0 == "--watchAll" }
  }

  /// A process, and the names of what it's running.
  struct Program: Sendable {
    let record: ProcessRecord
    let names: [String]

    /// The tool's name appears somewhere in a path it runs: ".../@playwright/mcp/cli.js".
    func mentions(_ tool: String) -> Bool {
      names.contains { $0.contains(tool) }
    }

    /// The tool is the command itself: "vite", ".../bin/vite" or ".../vite.js".
    func runs(_ tool: String) -> Bool {
      names.contains { DevToolClassifier.commandName(of: $0) == tool }
    }
  }
}
