import Foundation

/// Sorts each process's CPU share into rows. Your own processes land in the same rows as on the
/// RAM tab; macOS's processes, including root-owned ones, are split by subsystem.
enum CPUGroupBuilder {
  static func build(snapshot: CPUSnapshot, memoryGroups: [MemoryGroup]) -> [CPUGroup] {
    let groupByPid = memoryGroupsByPid(memoryGroups)
    var sharesByRow: [String: [CPUProcessShare]] = [:]
    var subsystemByRow: [String: MacOSSubsystem] = [:]
    var memoryGroupByRow: [String: MemoryGroup] = [:]

    for (pid, share) in snapshot.shareByPid where share > 0 {
      let path = snapshot.executablePathByPid[pid] ?? ""
      let name = (path as NSString).lastPathComponent
      let processShare = CPUProcessShare(pid: pid, name: name, share: share)
      if let group = groupByPid[pid], group.id != GroupKey.macOS.id {
        sharesByRow[group.id, default: []].append(processShare)
        memoryGroupByRow[group.id] = group
        continue
      }
      let subsystem = MacOSSubsystem.of(executablePath: path)
      let rowId = "macos-\(subsystem.rawValue)"
      sharesByRow[rowId, default: []].append(processShare)
      subsystemByRow[rowId] = subsystem
    }

    let rows = sharesByRow.map { rowId, shares in
      makeRow(
        id: rowId, shares: shares, memoryGroup: memoryGroupByRow[rowId], subsystem: subsystemByRow[rowId])
    }
    return (rows + unattributedRow(host: snapshot.host, rows: rows)).sorted { $0.share > $1.share }
  }

  /// Below this, the gap between the machine total and the named rows is just measuring noise.
  private static let unattributedThreshold = 0.01

  private static func unattributedRow(host: HostCPUUsage, rows: [CPUGroup]) -> [CPUGroup] {
    let gap = host.inUse - rows.reduce(0) { $0 + $1.share }
    guard gap >= unattributedThreshold else { return [] }
    let subsystem = MacOSSubsystem.unattributed
    return [
      CPUGroup(
        id: "macos-\(subsystem.rawValue)", title: subsystem.title, details: [],
        explanation: subsystem.explanation, share: gap, processes: [], memoryGroup: nil,
        subsystem: subsystem)
    ]
  }

  private static func memoryGroupsByPid(_ groups: [MemoryGroup]) -> [pid_t: MemoryGroup] {
    groups.reduce(into: [:]) { lookup, group in
      for process in group.processes {
        lookup[process.pid] = group
      }
    }
  }

  private static func makeRow(
    id: String, shares: [CPUProcessShare], memoryGroup: MemoryGroup?, subsystem: MacOSSubsystem?
  ) -> CPUGroup {
    let sorted = shares.sorted { $0.share > $1.share }
    let processCount = sorted.count == 1 ? "1 busy process" : "\(sorted.count) busy processes"
    let baseDetails = memoryGroup?.details.filter { !$0.hasSuffix("process") && !$0.hasSuffix("processes") } ?? []
    return CPUGroup(
      id: id,
      title: memoryGroup?.title ?? subsystem?.title ?? "Unknown",
      details: baseDetails + [processCount],
      explanation: memoryGroup?.explanation ?? subsystem?.explanation,
      share: sorted.reduce(0) { $0 + $1.share },
      processes: sorted,
      memoryGroup: memoryGroup,
      subsystem: subsystem
    )
  }
}
