/// When a process started. Together with the pid it identifies a process for certain,
/// because macOS reuses pids.
struct ProcessStartTime: Sendable, Hashable {
  let seconds: UInt64
  let microseconds: UInt64
}
