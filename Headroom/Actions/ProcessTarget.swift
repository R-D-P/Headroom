import Darwin

struct ProcessTarget: Sendable {
  let pid: pid_t
  let startTime: ProcessStartTime

  init(_ record: ProcessRecord) {
    pid = record.pid
    startTime = record.startTime
  }
}
