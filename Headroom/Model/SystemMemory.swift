/// Whole-machine memory, split the same way Activity Monitor splits it.
struct SystemMemory: Sendable, Equatable {
  let totalBytes: UInt64
  let appBytes: UInt64
  let wiredBytes: UInt64
  let compressedBytes: UInt64
  let cachedBytes: UInt64
  let swapUsedBytes: UInt64
  let pressure: MemoryPressure

  /// Activity Monitor's "Memory Used".
  var usedBytes: UInt64 { appBytes + wiredBytes + compressedBytes }

  /// 0–1: how much of the Mac's memory is in use.
  var usedFraction: Double {
    totalBytes > 0 ? min(1, Double(usedBytes) / Double(totalBytes)) : 0
  }

  /// Memory holding nothing at all.
  var unusedBytes: UInt64 {
    let taken = usedBytes + cachedBytes
    return totalBytes > taken ? totalBytes - taken : 0
  }

  /// What apps can have right now: unused memory plus cached files, which macOS drops the
  /// moment something needs the room.
  var freeBytes: UInt64 { unusedBytes + cachedBytes }
}
