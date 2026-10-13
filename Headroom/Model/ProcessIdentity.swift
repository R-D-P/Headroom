import Darwin

struct ProcessIdentity: Sendable, Hashable {
  let pid: pid_t
  let startTime: ProcessStartTime
}
