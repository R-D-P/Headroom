import SwiftUI

/// The summary when collapsed: the headline numbers on one line, above the bar.
struct CompactSummaryView<Bar: View>: View {
  let inUse: String
  var inUseCaption = "in use"
  let freeCaption: String
  let free: String
  let freeTint: Color
  @ViewBuilder let bar: Bar

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(Text(inUse).fontWeight(.semibold)) \(inUseCaption)")
        Spacer()
        Text("\(Text(free).fontWeight(.semibold).foregroundStyle(freeTint)) \(freeCaption)")
      }
      .font(.callout.monospacedDigit())
      bar
    }
  }
}
