import Foundation

/// Reads every process the user owns. Runs off the main thread; caches the expensive,
/// unchanging parts (arguments, paths) per process so a refresh only re-reads memory.
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

  private func cachedDetails(for identity: ProcessIdentity) -> ProcessDetails {
    if let cached = detailsCache[identity] {
      return cached
    }
    let details = ProcessDetails(
      executablePath: ProcessSyscalls.executablePath(of: identity.pid),
      arguments: ProcessSyscalls.arguments(of: identity.pid, buffer: &argumentBuffer),
      workingDirectory: ProcessSyscalls.workingDirectory(of: identity.pid),
      responsiblePid: ProcessSyscalls.responsiblePid(of: identity.pid)
    )
    detailsCache[identity] = details
    return details
  }
}
