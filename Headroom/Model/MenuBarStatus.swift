/// What the menu bar icon says: fine, worth a look, or in trouble, across RAM, CPU and battery.
struct MenuBarStatus: Equatable {
  enum Level: Comparable {
    case normal
    /// RAM or CPU over 80% used, or the battery under 20%.
    case warning
    /// RAM or CPU over 90% used, or the battery under 10%.
    case critical
  }

  let level: Level
  /// The readings in trouble, spelled out beside the icon so it says what's wrong: "CPU 94%".
  let criticalReadings: [String]
  /// Only a nearly flat battery pulses. A busy CPU is routine and would be a nuisance.
  let pulses: Bool

  init(memory: SystemMemory?, cpu: HostCPUUsage?, battery: BatteryStatus?) {
    let memoryLevel = memory.map { max(Self.level(used: $0.usedFraction), Self.level($0.pressure)) } ?? .normal
    let cpuLevel = cpu.map { Self.level(used: $0.inUse) } ?? .normal
    let batteryLevel: Level =
      switch battery?.warning {
      case .critical: .critical
      case .low: .warning
      case nil: .normal
      }

    var readings: [String] = []
    if memoryLevel == .critical, let memory {
      readings.append("RAM " + Self.percent(memory.usedFraction))
    }
    if cpuLevel == .critical, let cpu {
      readings.append("CPU " + Self.percent(cpu.inUse))
    }
    if batteryLevel == .critical, let battery {
      readings.append("Battery " + Self.percent(battery.charge))
    }

    level = max(memoryLevel, cpuLevel, batteryLevel)
    criticalReadings = readings
    pulses = batteryLevel == .critical
  }

  private static func level(used fraction: Double) -> Level {
    switch fraction {
    case 0.9...: .critical
    case 0.8...: .warning
    default: .normal
    }
  }

  private static func level(_ pressure: MemoryPressure) -> Level {
    switch pressure {
    case .normal: .normal
    case .warning: .warning
    case .critical: .critical
    }
  }

  private static func percent(_ fraction: Double) -> String {
    "\(Int((fraction * 100).rounded()))%"
  }
}
