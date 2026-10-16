import SwiftUI

/// A row's buttons joined into one segmented control. Each segment asks once before acting.
struct ActionSegmentsView: View {
  let group: MemoryGroup
  let isBusy: Bool
  let onAction: (GroupAction) -> Void

  var body: some View {
    if isBusy {
      ProgressView()
        .controlSize(.small)
    } else if !group.actions.isEmpty {
      HStack(spacing: 0) {
        ForEach(Array(group.actions.enumerated()), id: \.element) { index, action in
          if index > 0 {
            Divider()
              .frame(height: 12)
          }
          ConfirmingSegment(title: action.title, confirmTitle: group.confirmTitle(for: action)) {
            onAction(action)
          }
        }
      }
      .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
    }
  }
}

/// One segment: the first click arms it ("Quit?"), the second within three seconds runs it.
private struct ConfirmingSegment: View {
  let title: String
  let confirmTitle: String
  let action: () -> Void

  @State private var isArmed = false

  var body: some View {
    Button {
      guard isArmed else { return arm() }
      isArmed = false
      action()
    } label: {
      Text(isArmed ? confirmTitle : title)
        .font(.caption.weight(.medium))
        .foregroundStyle(isArmed ? Color.white : Color.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 6).fill(isArmed ? Color.red : .clear))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func arm() {
    isArmed = true
    Task {
      try? await Task.sleep(for: .seconds(3))
      isArmed = false
    }
  }
}
