/// Carries out a row's button and returns the sentence the panel shows afterwards.
@MainActor
enum GroupActionRunner {
  static func run(_ action: GroupAction, on group: MemoryGroup) async -> String {
    switch action {
    case .quit: await quit(group)
    case .restart: await restart(group)
    case .stop: await stop(group)
    }
  }

  private static func quit(_ group: MemoryGroup) async -> String {
    guard case .app(let pid, _) = group.kind else { return "\(group.title) isn't an app." }
    let didQuit = await AppLifecycle.quit(pid: pid)
    return didQuit ? "Quit \(group.title)." : "\(group.title) didn't quit. It may be asking you something."
  }

  private static func restart(_ group: MemoryGroup) async -> String {
    guard case .app(let pid, .some(let bundleURL)) = group.kind else {
      return "\(group.title) can't be restarted."
    }
    let didRestart = await AppLifecycle.restart(pid: pid, bundleURL: bundleURL)
    return didRestart
      ? "Restarted \(group.title)."
      : "\(group.title) didn't quit, so it wasn't restarted. It may be asking you something."
  }

  private static func stop(_ group: MemoryGroup) async -> String {
    let targets = group.processes.map(ProcessTarget.init)
    let survivors = await ProcessTreeStopper.stop(targets)
    guard survivors > 0 else {
      return "Stopped \(group.title), freeing about \(ByteFormatting.string(group.footprintBytes))."
    }
    return "\(survivors) of \(targets.count) processes in \(group.title) are still running."
  }
}
