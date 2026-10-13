/// Whole-machine CPU over the last sampling interval, as fractions of all cores combined.
struct HostCPUUsage: Sendable, Equatable {
  let user: Double
  let system: Double
  let idle: Double
  let loadAverages: [Double]
  let cores: CPUCores
  let thermalState: ThermalState

  var inUse: Double { user + system }

  var advice: String {
    switch (inUse, thermalState) {
    case (_, .serious), (_, .critical):
      "Your Mac is hot, so macOS is slowing it down to cool it."
    case (0.8..., _): "Your Mac is working flat out. Things may feel slow."
    case (0.5..., _): "Your Mac is busy, but has room to spare."
    default: "Mostly idle. Plenty of CPU to spare."
    }
  }
}
