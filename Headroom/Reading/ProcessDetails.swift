import Darwin

/// The parts of a process that don't change while it runs, cached between refreshes.
struct ProcessDetails: Sendable {
  let executablePath: String
  let arguments: [String]
  let workingDirectory: String?
  let responsiblePid: pid_t
}
