import Foundation

/// Memory sizes in Activity Monitor's units (1 GB = 1024³ bytes).
enum ByteFormatting {
  private static let megabyte = 1_048_576.0
  private static let gigabyte = 1_073_741_824.0

  /// "472 MB", "2.16 GB", "13.1 GB", "16 GB".
  static func string(_ bytes: UInt64) -> String {
    let value = Double(bytes)
    guard value >= gigabyte else { return String(format: "%.0f MB", value / megabyte) }
    let gigabytes = value / gigabyte
    if gigabytes.rounded() == gigabytes {
      return String(format: "%.0f GB", gigabytes)
    }
    return String(format: gigabytes >= 10 ? "%.1f GB" : "%.2f GB", gigabytes)
  }

  /// Shorter form for the menu bar: "9.1 GB".
  static func compact(_ bytes: UInt64) -> String {
    String(format: "%.1f GB", Double(bytes) / gigabyte)
  }
}
