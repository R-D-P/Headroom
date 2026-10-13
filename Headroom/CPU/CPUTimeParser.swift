import Darwin

/// Parses `ps -axo pid=,time=,comm=` output. `time` looks like "4:01.99" (minutes:seconds),
/// and may grow hour and day fields ("1-02:03:04.56") on long-running processes.
enum CPUTimeParser {
  static func parse(_ output: String) -> [ProcessCPUTime] {
    output.split(separator: "\n").compactMap(parseLine)
  }

  private static func parseLine(_ line: Substring) -> ProcessCPUTime? {
    let fields = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
    guard fields.count == 3, let pid = pid_t(fields[0]), let seconds = seconds(in: fields[1]) else {
      return nil
    }
    return ProcessCPUTime(pid: pid, cpuSeconds: seconds, executablePath: String(fields[2]))
  }

  private static func seconds(in time: Substring) -> Double? {
    let dayParts = time.split(separator: "-")
    let days = dayParts.count == 2 ? Double(dayParts[0]) ?? 0 : 0
    let clock = dayParts.last ?? time
    let units = clock.split(separator: ":").compactMap { Double($0) }
    guard !units.isEmpty else { return nil }
    let clockSeconds = units.reduce(0) { $0 * 60 + $1 }
    return days * 86_400 + clockSeconds
  }
}
