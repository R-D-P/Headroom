import Foundation

/// CPU time for every process on the Mac, root-owned ones included. Headroom can't read
/// root processes itself, but `/bin/ps` is setuid root and reports them for anyone.
enum ProcessCPUSampler {
  static func sample() -> [ProcessCPUTime] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/ps")
    process.arguments = ["-axo", "pid=,time=,comm="]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
    } catch {
      return []
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return CPUTimeParser.parse(String(decoding: data, as: UTF8.self))
  }
}
