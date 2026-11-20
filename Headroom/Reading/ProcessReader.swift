import Foundation

/// Reads every process the user owns. Runs off the main thread; caches the expensive,
/// rarely changing parts (arguments, working directory) per process so a refresh mostly
/// re-reads memory.
actor ProcessReader {
  private var detailsCache: [ProcessIdentity: ProcessDetails] = [:]
  private var argumentBuffer = [UInt8](repeating: 0, count: ProcessSyscalls.maximumArgumentsSize())

  func read() -> ProcessSnapshot {
    var records: [pid_t: ProcessRecord] = [:]
    var unreadableCount = 0
    var seen = Set<ProcessIdentity>()

    for pid in ProcessSyscalls.allPids() {
      guard let footprint = ProcessSyscalls.footprint(of: pid),
        let info = ProcessSyscalls.bsdInfo(of: pid), !info.isZombie
      else {
        unreadableCount += 1
        continue
      }
      let identity = ProcessIdentity(pid: pid, startTime: info.startTime)
      seen.insert(identity)
      let details = cachedDetails(for: identity)
      records[pid] = ProcessRecord(
        pid: pid,
        parentPid: info.parentPid,
        responsiblePid: details.responsiblePid,
        startTime: info.startTime,
        name: info.name,
        executablePath: details.executablePath,
        arguments: details.arguments,
        workingDirectory: details.workingDirectory,
        footprintBytes: footprint
      )
    }

    detailsCache = detailsCache.filter { seen.contains($0.key) }
    return ProcessSnapshot(records: records, unreadableCount: unreadableCount, takenAt: Date())
  }

  /// A process that calls exec keeps its pid and start time but becomes a different program
  /// (a wrapper script turning into the server it starts), so the path is checked every time.
  private func cachedDetails(for identity: ProcessIdentity) -> ProcessDetails {
    let executablePath = ProcessSyscalls.executablePath(of: identity.pid)
    if let cached = detailsCache[identity], cached.executablePath == executablePath {
      return cached
    }
    let details = ProcessDetails(
      executablePath: executablePath,
      arguments: ProcessSyscalls.arguments(of: identity.pid, buffer: &argumentBuffer),
      workingDirectory: ProcessSyscalls.workingDirectory(of: identity.pid),
      responsiblePid: ProcessSyscalls.responsiblePid(of: identity.pid)
    )
    detailsCache[identity] = details
    return details
  }
}
