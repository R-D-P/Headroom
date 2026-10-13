import SwiftUI

/// The whole machine's RAM as one bar. Unused memory is the empty track behind the segments.
struct MemoryBarView: View {
  let memory: SystemMemory

  private let drawnSegments: [MemorySegment] = [.apps, .wired, .compressed, .cached]

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 1.5) {
        ForEach(drawnSegments) { segment in
          Rectangle()
            .fill(segment.color)
            .frame(width: width(of: segment, in: geometry.size.width))
        }
        Spacer(minLength: 0)
      }
    }
    .frame(height: 12)
    .background(MemorySegment.unused.color)
    .clipShape(Capsule())
    .animation(.smooth, value: memory)
  }

  private func width(of segment: MemorySegment, in totalWidth: CGFloat) -> CGFloat {
    guard memory.totalBytes > 0 else { return 0 }
    let fraction = Double(segment.bytes(in: memory)) / Double(memory.totalBytes)
    return max(0, totalWidth * fraction)
  }
}
