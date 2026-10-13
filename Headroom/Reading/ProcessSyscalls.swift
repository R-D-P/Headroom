import Darwin

/// Private but long-stable libSystem call that Activity Monitor uses to tie helpers to their app.
@_silgen_name("responsibility_get_pid_responsible_for_pid")
private func responsibilityGetPidResponsibleForPid(_ pid: pid_t) -> pid_t

/// Thin wrappers over the libproc and sysctl calls Headroom reads processes with.
/// All of them work without admin rights for the current user's own processes.
enum ProcessSyscalls {
  private static let zombieStatus: UInt32 = 5  // SZOMB in <sys/proc.h>

  static func allPids() -> [pid_t] {
    let estimate = proc_listallpids(nil, 0)
    guard estimate > 0 else { return [] }
    var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
    let count = pids.withUnsafeMutableBytes { buffer in
      proc_listallpids(buffer.baseAddress, Int32(buffer.count))
    }
    return pids.prefix(Int(max(count, 0))).filter { $0 > 0 }
  }

  static func footprint(of pid: pid_t) -> UInt64? {
    var usage = rusage_info_v4()
    let result = withUnsafeMutablePointer(to: &usage) { pointer in
      pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
        proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
      }
    }
    return result == 0 ? usage.ri_phys_footprint : nil
  }

  static func bsdInfo(of pid: pid_t) -> BSDProcessInfo? {
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
    let longName = CStringTuple.string(from: info.pbi_name)
    return BSDProcessInfo(
      parentPid: pid_t(info.pbi_ppid),
      name: longName.isEmpty ? CStringTuple.string(from: info.pbi_comm) : longName,
      startTime: ProcessStartTime(seconds: info.pbi_start_tvsec, microseconds: info.pbi_start_tvusec),
      isZombie: info.pbi_status == zombieStatus
    )
  }

  static func executablePath(of pid: pid_t) -> String {
    var buffer = [UInt8](repeating: 0, count: 4 * Int(MAXPATHLEN))
    let length = buffer.withUnsafeMutableBytes { proc_pidpath(pid, $0.baseAddress, UInt32($0.count)) }
    guard length > 0 else { return "" }
    return String(decoding: buffer.prefix(Int(length)), as: UTF8.self)
  }

  static func workingDirectory(of pid: pid_t) -> String? {
    var info = proc_vnodepathinfo()
    let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
    let path = CStringTuple.string(from: info.pvi_cdir.vip_path)
    return path.isEmpty ? nil : path
  }

  static func arguments(of pid: pid_t, buffer: inout [UInt8]) -> [String] {
    var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
    var size = buffer.count
    let result = buffer.withUnsafeMutableBytes { sysctl(&mib, 3, $0.baseAddress, &size, nil, 0) }
    guard result == 0, size > MemoryLayout<Int32>.size else { return [] }
    let argumentCount = buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
    return ProcessArgumentsParser.parse(buffer[0..<size], argumentCount: Int(argumentCount))
  }

  static func maximumArgumentsSize() -> Int {
    var mib: [Int32] = [CTL_KERN, KERN_ARGMAX]
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctl(&mib, 2, &value, &size, nil, 0) == 0, value > 0 else { return 1 << 20 }
    return Int(value)
  }

  static func responsiblePid(of pid: pid_t) -> pid_t {
    let owner = responsibilityGetPidResponsibleForPid(pid)
    return owner > 0 ? owner : pid
  }
}
