import Darwin

struct BSDProcessInfo: Sendable {
  let parentPid: pid_t
  let name: String
  let startTime: ProcessStartTime
  let isZombie: Bool
}
