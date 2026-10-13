import SwiftUI

/// CPU use needs two readings a moment apart, so the very first look shows this briefly.
struct MeasuringView: View {
  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
        .controlSize(.small)
      Text("Measuring CPU…")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 120)
  }
}
