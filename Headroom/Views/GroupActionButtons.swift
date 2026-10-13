import SwiftUI

struct GroupActionButtons: View {
  let group: MemoryGroup
  let isBusy: Bool
  let onAction: (GroupAction) -> Void

  var body: some View {
    if isBusy {
      ProgressView()
        .controlSize(.small)
    } else {
      HStack(spacing: 4) {
        ForEach(group.actions, id: \.self) { action in
          ConfirmingButton(title: action.title, confirmTitle: group.confirmTitle(for: action)) {
            onAction(action)
          }
        }
      }
    }
  }
}
