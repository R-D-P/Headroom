import Darwin

/// Total CPU time a process has used since it started, as `ps` reports it.
struct ProcessCPUTime: Sendable {
  let pid: pid_t
  let cpuSeconds: Double
  let executablePath: String
}
