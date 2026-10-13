import SwiftUI

struct CPUProcessListView: View {
  let processes: [CPUProcessShare]

  private static let maximumShown = 12

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      ForEach(processes.prefix(Self.maximumShown)) { process in
        HStack(spacing: 8) {
          Text(process.name)
            .lineLimit(1)
            .truncationMode(.middle)
          Text(verbatim: "\(process.pid)")
            .foregroundStyle(.tertiary)
          Spacer()
          Text(PercentFormatting.string(process.share))
            .foregroundStyle(.secondary)
        }
        .font(.caption.monospacedDigit())
      }
      if processes.count > Self.maximumShown {
        Text("and \(processes.count - Self.maximumShown) more")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.leading, 40)
  }
}
