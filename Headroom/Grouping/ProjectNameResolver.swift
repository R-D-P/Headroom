import Foundation

/// Names the project a process works on: the git repo (or worktree) containing its working
/// directory, or failing that, one of the paths in its arguments.
@MainActor
final class ProjectNameResolver {
  private var cache: [String: String?] = [:]
  private let homeDirectory = NSHomeDirectory()
  private static let maximumArgumentsChecked = 24

  func name(for record: ProcessRecord) -> String? {
    let argumentPaths = record.arguments.prefix(Self.maximumArgumentsChecked)
      .filter { $0.hasPrefix(homeDirectory + "/") }
    let candidates = [record.workingDirectory].compactMap { $0 } + argumentPaths
    return candidates.lazy.compactMap { self.repositoryName(containing: $0) }.first
  }

  private func repositoryName(containing path: String) -> String? {
    if let cached = cache[path] {
      return cached
    }
    let name = searchUpwardForRepository(from: path)
    cache[path] = name
    return name
  }

  private func searchUpwardForRepository(from path: String) -> String? {
    var directory = URL(fileURLWithPath: path)
    while directory.path != "/", directory.path != homeDirectory {
      // A worktree has a `.git` file rather than a folder; both count.
      if FileManager.default.fileExists(atPath: directory.appendingPathComponent(".git").path) {
        return directory.lastPathComponent
      }
      directory.deleteLastPathComponent()
    }
    return nil
  }
}
