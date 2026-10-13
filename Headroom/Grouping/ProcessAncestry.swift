import Darwin

/// Walks parent links to decide which row each process belongs to.
///
/// macOS charges anything started in a terminal to the terminal app, so on its own the
/// "responsible app" lumps every dev server into one giant terminal row. Walking up the
/// parent chain lets Headroom pull out the pieces that matter:
/// - the outermost dev tool below any Claude session becomes its own row, so a whole Meteor
///   tree (dotenvx → meteor → rspack ×2 → app server) is one "Meteor dev server" row;
/// - otherwise the nearest Claude Code session claims the process (its shells, MCP servers);
/// - otherwise, if the process tree was left behind by an app (its top process's parent has
///   exited, and it isn't part of the app's own bundle), that tree becomes its own row;
/// - otherwise the process falls back to its responsible app.
struct ProcessAncestry {
  let records: [pid_t: ProcessRecord]
  let apps: [pid_t: RunningAppInfo]

  private static let maximumDepth = 64

  func groupKey(for record: ProcessRecord) -> GroupKey {
    let chain = ancestors(of: record)
    let sessionIndex = chain.firstIndex(where: ClaudeSessionDetector.isSession)
    let belowSession = chain[..<(sessionIndex ?? chain.endIndex)]
    if let devToolRoot = belowSession.last(where: { DevToolClassifier.kind(of: $0) != nil }) {
      return .devTool(devToolRoot.pid)
    }
    if let sessionIndex {
      return .claudeSession(chain[sessionIndex].pid)
    }
    if let detachedRoot = chain.last, isLeftBehind(detachedRoot) {
      return .process(detachedRoot.pid)
    }
    return ownerKey(for: record)
  }

  /// A process whose parent exited (so launchd adopted it) but which macOS still charges to an
  /// app it isn't part of: a build service outliving its build, a server outliving its terminal tab.
  /// macOS's own XPC helpers (shader compiler, video encoder…) also run under launchd on an app's
  /// behalf; that's normal, so anything shipped with macOS stays with its app.
  func isLeftBehind(_ record: ProcessRecord) -> Bool {
    guard record.parentPid == 1, apps[record.pid] == nil, record.responsiblePid != record.pid,
      !SystemPathDetector.isSystem(record.executablePath),
      let app = apps[record.responsiblePid], !app.belongsToMacOS
    else { return false }
    guard let bundlePath = app.bundleURL?.path else { return true }
    return !record.executablePath.hasPrefix(bundlePath + "/")
  }

  /// The Claude Code session that started this process, if any.
  func claudeSession(above record: ProcessRecord) -> ProcessRecord? {
    ancestors(of: record).dropFirst().first(where: ClaudeSessionDetector.isSession)
  }

  /// The process itself, then its parent, grandparent… stopping at an app or at launchd.
  private func ancestors(of record: ProcessRecord) -> [ProcessRecord] {
    var chain = [record]
    var current = record
    while apps[current.pid] == nil, current.parentPid > 1, chain.count < Self.maximumDepth,
      let parent = records[current.parentPid]
    {
      chain.append(parent)
      current = parent
    }
    return chain
  }

  private func ownerKey(for record: ProcessRecord) -> GroupKey {
    let ownerPid = record.responsiblePid
    if let app = apps[ownerPid] {
      return app.belongsToMacOS ? .macOS : .app(ownerPid)
    }
    let ownerPath = records[ownerPid]?.executablePath ?? record.executablePath
    return SystemPathDetector.isSystem(ownerPath) ? .macOS : .process(ownerPid)
  }
}
