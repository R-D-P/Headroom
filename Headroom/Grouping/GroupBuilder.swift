import Darwin

/// Turns a process snapshot into the rows the panel shows: largest first, with macOS itself
/// last because nothing in it can be acted on.
@MainActor
final class GroupBuilder {
  private let projectNames = ProjectNameResolver()

  func build(
    snapshot: ProcessSnapshot, apps: [pid_t: RunningAppInfo], selfPid: pid_t
  ) -> [MemoryGroup] {
    let ancestry = ProcessAncestry(records: snapshot.records, apps: apps)
    let membersByKey = Dictionary(grouping: snapshot.records.values) { ancestry.groupKey(for: $0) }
    return membersByKey
      .map { key, members in
        makeGroup(
          key: key, members: members, ancestry: ancestry, selfPid: selfPid,
          unreadableCount: snapshot.unreadableCount)
      }
      .sorted(by: Self.listOrder)
  }

  private static func listOrder(_ first: MemoryGroup, _ second: MemoryGroup) -> Bool {
    let firstIsMacOS = first.id == GroupKey.macOS.id
    let secondIsMacOS = second.id == GroupKey.macOS.id
    guard firstIsMacOS == secondIsMacOS else { return secondIsMacOS }
    return first.footprintBytes > second.footprintBytes
  }

  private func makeGroup(
    key: GroupKey, members: [ProcessRecord], ancestry: ProcessAncestry, selfPid: pid_t,
    unreadableCount: Int
  ) -> MemoryGroup {
    let processes = members.sorted { $0.footprintBytes > $1.footprintBytes }
    var description = describe(key: key, ancestry: ancestry, selfPid: selfPid)
    description.details.append(processes.count == 1 ? "1 process" : "\(processes.count) processes")
    if case .macOS = key {
      description.explanation? += " Another \(unreadableCount) system processes run as root; they're in the bar above but can't be broken down."
    }
    return MemoryGroup(
      id: key.id,
      kind: description.kind,
      title: description.title,
      details: description.details,
      explanation: description.explanation,
      footprintBytes: processes.reduce(0) { $0 + $1.footprintBytes },
      processes: processes,
      isOrphaned: description.isOrphaned,
      startedByClaudeSession: description.startedByClaudeSession,
      isSelf: description.isSelf
    )
  }

  private func describe(key: GroupKey, ancestry: ProcessAncestry, selfPid: pid_t) -> GroupDescription {
    switch key {
    case .app(let pid):
      guard let app = ancestry.apps[pid] else { return describeProcess(pid: pid, ancestry: ancestry) }
      return describeApp(app, selfPid: selfPid)
    case .devTool(let pid):
      guard let root = ancestry.records[pid] else { return describeProcess(pid: pid, ancestry: ancestry) }
      return describeDevTool(root: root, ancestry: ancestry)
    case .claudeSession(let pid):
      guard let root = ancestry.records[pid] else { return describeProcess(pid: pid, ancestry: ancestry) }
      return describeClaudeSession(root: root)
    case .process(let pid):
      return describeProcess(pid: pid, ancestry: ancestry)
    case .macOS:
      return GroupDescription(
        kind: .macOS,
        title: "macOS services",
        explanation: "Parts of macOS running for your login session. macOS manages these; they can't be quit."
      )
    }
  }

  private func describeApp(_ app: RunningAppInfo, selfPid: pid_t) -> GroupDescription {
    GroupDescription(
      kind: .app(pid: app.pid, bundleURL: app.bundleURL),
      title: app.name,
      explanation: AppExplanation.text(for: app),
      isSelf: app.pid == selfPid
    )
  }

  private func describeDevTool(root: ProcessRecord, ancestry: ProcessAncestry) -> GroupDescription {
    let kind = DevToolClassifier.kind(of: root) ?? .script
    let session = ancestry.claudeSession(above: root).map(ClaudeSessionDetector.label(for:))
    let isOrphaned = root.parentPid == 1 && kind.canBeOrphaned
    var description = GroupDescription(
      kind: .devTool(kind),
      title: kind == .script ? "\(kind.title): \(ProcessDisplayName.make(for: root))" : kind.title,
      explanation: kind.explanation,
      isOrphaned: isOrphaned,
      startedByClaudeSession: session
    )
    description.details = devToolDetails(root: root, session: session, ancestry: ancestry)
    if isOrphaned {
      description.explanation? += " Its parent process is gone, so nothing will stop it for you."
    }
    return description
  }

  private func devToolDetails(
    root: ProcessRecord, session: String?, ancestry: ProcessAncestry
  ) -> [String] {
    var details: [String] = []
    if let project = projectNames.name(for: root) {
      details.append(project)
    }
    if let port = ArgumentParsing.port(in: root.arguments) {
      details.append(":\(port)")
    }
    if let session {
      details.append("started by \(session)")
    } else if root.parentPid != 1, let app = ancestry.apps[root.responsiblePid] {
      details.append("started in \(app.name)")
    }
    return details
  }

  private func describeClaudeSession(root: ProcessRecord) -> GroupDescription {
    var details: [String] = []
    if let project = projectNames.name(for: root) {
      details.append(project)
    }
    if let sessionId = ClaudeSessionDetector.shortSessionId(of: root) {
      details.append("session \(sessionId)")
    }
    let isOrphaned = root.parentPid == 1
    return GroupDescription(
      kind: .claudeSession,
      title: "Claude Code session",
      details: details,
      explanation: isOrphaned
        ? "Claude Code whose terminal has closed. Nothing will stop it for you."
        : "Claude Code, plus the shells and MCP servers it started. Dev servers it started have their own rows.",
      isOrphaned: isOrphaned
    )
  }

  private func describeProcess(pid: pid_t, ancestry: ProcessAncestry) -> GroupDescription {
    let owner = ancestry.records[pid]
    let title =
      owner.flatMap { AppBundleName.from(path: $0.executablePath) }
      ?? owner.map(ProcessDisplayName.make(for:)) ?? "Process \(pid)"
    guard let owner, ancestry.isLeftBehind(owner), let app = ancestry.apps[owner.responsiblePid] else {
      return GroupDescription(kind: .process, title: title)
    }
    var details: [String] = []
    if let project = projectNames.name(for: owner) {
      details.append(project)
    }
    details.append("started in \(app.name)")
    return GroupDescription(
      kind: .process,
      title: title,
      details: details,
      explanation: "Left behind: whatever started it has exited, so nothing will stop it for you.",
      isOrphaned: true
    )
  }
}
