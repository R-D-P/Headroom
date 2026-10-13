import Darwin

struct CPUProcessShare: Sendable, Identifiable {
  let pid: pid_t
  let name: String
  let share: Double

  var id: pid_t { pid }
}
