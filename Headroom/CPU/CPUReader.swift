import Foundation

/// Measures CPU by taking two readings and comparing them, so the first call returns nothing.
actor CPUReader {
  private var previousHost: HostCPUTicks?
  private var previousProcesses: [pid_t: Double] = [:]
  private var previousTime: Date?
  private let cores = CPUCores.read()

  func sample() -> CPUSnapshot? {
    let now = Date()
    let host = HostCPUTicks.read()
    let processes = ProcessCPUSampler.sample()
    defer {
      previousHost = host
      previousProcesses = Dictionary(processes.map { ($0.pid, $0.cpuSeconds) }) { first, _ in first }
      previousTime = now
    }
    guard let host, let previousHost, let previousTime else { return nil }

    let capacitySeconds = now.timeIntervalSince(previousTime) * Double(cores.total)
    guard capacitySeconds > 0 else { return nil }
    return CPUSnapshot(
      host: usage(from: previousHost, to: host),
      shareByPid: shares(of: processes, capacitySeconds: capacitySeconds),
      executablePathByPid: Dictionary(processes.map { ($0.pid, $0.executablePath) }) { first, _ in first }
    )
  }

  private func usage(from earlier: HostCPUTicks, to later: HostCPUTicks) -> HostCPUUsage {
    let total = Double(later.total &- earlier.total)
    let fraction = { (ticks: UInt64) in total > 0 ? Double(ticks) / total : 0 }
    var loads = [Double](repeating: 0, count: 3)
    getloadavg(&loads, 3)
    return HostCPUUsage(
      user: fraction(later.user &- earlier.user),
      system: fraction(later.system &- earlier.system),
      idle: fraction(later.idle &- earlier.idle),
      loadAverages: loads,
      cores: cores,
      thermalState: ThermalState(ProcessInfo.processInfo.thermalState)
    )
  }

  private func shares(of processes: [ProcessCPUTime], capacitySeconds: Double) -> [pid_t: Double] {
    processes.reduce(into: [:]) { shares, process in
      // A process missing from the previous reading started since then, so all its time is new.
      let before = previousProcesses[process.pid] ?? 0
      guard process.cpuSeconds > before else { return }
      shares[process.pid] = min(1, (process.cpuSeconds - before) / capacitySeconds)
    }
  }
}
