import SwiftUI

/// Dev servers and tools Headroom lists on their own instead of under the terminal that started them.
enum DevToolKind: Sendable, Hashable {
  case meteor
  case mongo
  case postgres
  case redis
  case watchman
  case storybook
  case playwright
  case nextjs
  case vite
  case jestWatch
  case typescriptWatch
  case bundler
  case nodemon
  case script

  var title: String {
    switch self {
    case .meteor: "Meteor dev server"
    case .mongo: "MongoDB"
    case .postgres: "PostgreSQL"
    case .redis: "Redis"
    case .watchman: "Watchman"
    case .storybook: "Storybook"
    case .playwright: "Playwright"
    case .nextjs: "Next.js dev server"
    case .vite: "Vite dev server"
    case .jestWatch: "Jest (watch mode)"
    case .typescriptWatch: "TypeScript (watch mode)"
    case .bundler: "Bundler (watch mode)"
    case .nodemon: "nodemon"
    case .script: "Script"
    }
  }

  var explanation: String {
    switch self {
    case .meteor:
      "App server plus two Rspack bundlers. They keep the whole module graph in memory so rebuilds are fast."
    case .mongo: "Local database server."
    case .postgres: "Local database server."
    case .redis: "Local in-memory data store."
    case .watchman: "File watcher used by Jest and other tools. Safe to stop; it starts again when needed."
    case .storybook: "Component workshop dev server."
    case .playwright: "Playwright test runner, MCP server or the browsers it drives."
    case .nextjs: "Next.js dev server."
    case .vite: "Vite dev server."
    case .jestWatch: "Re-runs tests whenever files change."
    case .typescriptWatch: "Re-checks types whenever files change."
    case .bundler: "Rebuilds whenever files change, keeping the module graph in memory."
    case .nodemon: "Restarts a script whenever files change."
    case .script: "A script running on its own."
    }
  }

  var symbolName: String {
    switch self {
    case .meteor: "flame"
    case .mongo, .postgres, .redis: "cylinder.split.1x2"
    case .watchman: "eye"
    case .storybook: "book"
    case .playwright: "theatermasks"
    case .nextjs, .vite, .bundler: "shippingbox"
    case .jestWatch: "checkmark.seal"
    case .typescriptWatch: "chevron.left.forwardslash.chevron.right"
    case .nodemon, .script: "terminal"
    }
  }

  var tint: Color {
    switch self {
    case .meteor: .orange
    case .mongo, .postgres, .redis: .green
    case .playwright, .jestWatch: .pink
    default: .indigo
    }
  }

  /// Watchman always runs detached by design, so "orphaned" would be misleading for it.
  var canBeOrphaned: Bool { self != .watchman }
}
