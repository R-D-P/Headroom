import Darwin

/// Whole-machine memory from the kernel, computed the way Activity Monitor computes it.
enum SystemMemoryReader {
  private static let hostPort = mach_host_self()

  static func read() -> SystemMemory {
    let stats = virtualMemoryStatistics()
    let pageSize = UInt64(getpagesize())
    let internalPages = UInt64(stats.internal_page_count)
    let purgeablePages = UInt64(stats.purgeable_count)

    return SystemMemory(
      totalBytes: sysctlValue("hw.memsize", as: UInt64.self) ?? 0,
      appBytes: (internalPages > purgeablePages ? internalPages - purgeablePages : 0) * pageSize,
      wiredBytes: UInt64(stats.wire_count) * pageSize,
      compressedBytes: UInt64(stats.compressor_page_count) * pageSize,
      cachedBytes: (UInt64(stats.external_page_count) + purgeablePages) * pageSize,
      swapUsedBytes: sysctlValue("vm.swapusage", as: xsw_usage.self)?.xsu_used ?? 0,
      pressure: MemoryPressure(
        kernelLevel: sysctlValue("kern.memorystatus_vm_pressure_level", as: Int32.self) ?? 1)
    )
  }

  private static func virtualMemoryStatistics() -> vm_statistics64 {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    _ = withUnsafeMutablePointer(to: &stats) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
      }
    }
    return stats
  }

  private static func sysctlValue<Value>(_ name: String, as type: Value.Type) -> Value? {
    let pointer = UnsafeMutablePointer<Value>.allocate(capacity: 1)
    defer { pointer.deallocate() }
    var size = MemoryLayout<Value>.size
    guard sysctlbyname(name, pointer, &size, nil, 0) == 0 else { return nil }
    return pointer.pointee
  }
}
