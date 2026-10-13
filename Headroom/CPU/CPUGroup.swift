/// One row on the CPU tab. Rows for your own apps and tools carry the matching RAM-tab row, which
/// supplies the icon, details and buttons; macOS jobs carry their subsystem instead.
struct CPUGroup: Identifiable, Sendable {
  let id: String
  let title: String
  let details: [String]
  let explanation: String?
  let share: Double
  let processes: [CPUProcessShare]
  let memoryGroup: MemoryGroup?
  let subsystem: MacOSSubsystem?
}
