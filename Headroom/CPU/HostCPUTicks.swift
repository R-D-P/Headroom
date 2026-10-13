import Darwin

/// Whole-machine CPU time since boot, summed over every core, in scheduler ticks.
struct HostCPUTicks: Sendable {
  let user: UInt64
  let system: UInt64
  let idle: UInt64

  var total: UInt64 { user + system + idle }

  static func read() -> HostCPUTicks? {
    var coreCount: natural_t = 0
    var info: processor_info_array_t?
    var infoCount: mach_msg_type_number_t = 0
    guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &coreCount, &info, &infoCount)
      == KERN_SUCCESS, let info
    else { return nil }
    defer {
      vm_deallocate(
        mach_task_self_, vm_address_t(bitPattern: info),
        vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
    }

    var user: UInt64 = 0
    var system: UInt64 = 0
    var idle: UInt64 = 0
    for core in 0..<Int(coreCount) {
      let base = core * Int(CPU_STATE_MAX)
      user += UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]))
      user += UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]))
      system += UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]))
      idle += UInt64(UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)]))
    }
    return HostCPUTicks(user: user, system: system, idle: idle)
  }
}
