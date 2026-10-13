import Foundation

/// How many cores the Mac has, split into performance and efficiency cores on Apple silicon.
struct CPUCores: Sendable, Equatable {
  let total: Int
  let performance: Int
  let efficiency: Int

  static func read() -> CPUCores {
    let total = integer("hw.ncpu") ?? ProcessInfo.processInfo.activeProcessorCount
    return CPUCores(
      total: total,
      performance: integer("hw.perflevel0.logicalcpu") ?? total,
      efficiency: integer("hw.perflevel1.logicalcpu") ?? 0
    )
  }

  var summary: String {
    guard efficiency > 0 else { return "\(total) cores" }
    return "\(total) cores (\(performance) performance, \(efficiency) efficiency)"
  }

  private static func integer(_ name: String) -> Int? {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return Int(value)
  }
}
