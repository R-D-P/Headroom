import SwiftUI

struct CPUTableView: View {
  let usage: HostCPUUsage

  var body: some View {
    VStack(spacing: 5) {
      TableRowView(
        title: "Apps", explanation: "Work your apps and tools are doing",
        value: PercentFormatting.string(usage.user), color: .blue)
      TableRowView(
        title: "macOS", explanation: "The system working on their behalf",
        value: PercentFormatting.string(usage.system), color: .red.opacity(0.8))
      TableRowView(title: "In use", value: PercentFormatting.string(usage.inUse), isTotal: true)
      TableRowView(
        title: "Idle", value: PercentFormatting.string(usage.idle), color: MemorySegment.unused.color,
        isTotal: true)
      Divider()
      TableRowView(
        title: "Load", explanation: "Busy threads, averaged over 1 / 5 / 15 min",
        value: loadAverages)
      TableRowView(title: "Cores", explanation: usage.cores.summary, value: "\(usage.cores.total)")
      TableRowView(
        title: "Temperature", explanation: "Hot Macs are slowed down to cool off",
        value: usage.thermalState.title, color: usage.thermalState.tint)
    }
  }

  private var loadAverages: String {
    usage.loadAverages.map { String(format: "%.1f", $0) }.joined(separator: " / ")
  }
}
