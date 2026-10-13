import Darwin

/// Stops a set of processes politely (SIGTERM), waits up to three seconds, then forcefully
/// (SIGKILL). Before every signal it checks the pid still belongs to the same process, so a
/// recycled pid can never be hit by mistake.
enum ProcessTreeStopper {
  private static let politeAttempts = 15
  private static let pollInterval = Duration.milliseconds(200)

  /// Returns how many processes are still running afterwards.
  static func stop(_ targets: [ProcessTarget]) async -> Int {
    let safeTargets = targets.filter { $0.pid > 1 && $0.pid != getpid() }
    send(SIGTERM, to: safeTargets)
    for _ in 0..<politeAttempts {
      if survivors(of: safeTargets).isEmpty {
        return 0
      }
      try? await Task.sleep(for: pollInterval)
    }
    send(SIGKILL, to: survivors(of: safeTargets))
    try? await Task.sleep(for: pollInterval)
    return survivors(of: safeTargets).count
  }

  private static func send(_ signal: Int32, to targets: [ProcessTarget]) {
    for target in targets where isAlive(target) {
      kill(target.pid, signal)
    }
  }

  private static func survivors(of targets: [ProcessTarget]) -> [ProcessTarget] {
    targets.filter(isAlive)
  }

  private static func isAlive(_ target: ProcessTarget) -> Bool {
    guard let info = ProcessSyscalls.bsdInfo(of: target.pid) else { return false }
    return info.startTime == target.startTime && !info.isZombie
  }
}
