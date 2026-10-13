import Foundation

struct CPUSnapshot: Sendable {
  let host: HostCPUUsage
  /// Share of the whole Mac each process used over the interval: 0.25 means a quarter of all cores.
  let shareByPid: [pid_t: Double]
  let executablePathByPid: [pid_t: String]
}
