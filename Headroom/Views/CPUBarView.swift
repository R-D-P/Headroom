import SwiftUI

struct CPUBarView: View {
  let usage: HostCPUUsage

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 1.5) {
        Rectangle()
          .fill(Color.blue)
          .frame(width: geometry.size.width * usage.user)
        Rectangle()
          .fill(Color.red.opacity(0.8))
          .frame(width: geometry.size.width * usage.system)
        Spacer(minLength: 0)
      }
    }
    .frame(height: 12)
    .background(MemorySegment.unused.color)
    .clipShape(Capsule())
    .animation(.smooth, value: usage)
  }
}
