/// Parses the `KERN_PROCARGS2` layout: argc, the executable path, padding, then argv.
enum ProcessArgumentsParser {
  static func parse(_ bytes: ArraySlice<UInt8>, argumentCount: Int) -> [String] {
    var index = bytes.startIndex + MemoryLayout<Int32>.size
    while index < bytes.endIndex, bytes[index] != 0 { index += 1 }
    while index < bytes.endIndex, bytes[index] == 0 { index += 1 }

    var arguments: [String] = []
    var start = index
    while index < bytes.endIndex, arguments.count < argumentCount {
      if bytes[index] == 0 {
        arguments.append(String(decoding: bytes[start..<index], as: UTF8.self))
        start = index + 1
      }
      index += 1
    }
    return arguments
  }
}
