import SwiftUI

/// The first click arms the button ("Stop?"), the second within three seconds runs it.
/// Works inside the menu bar panel, where confirmation dialogs would close the panel.
struct ConfirmingButton: View {
  let title: String
  let confirmTitle: String
  let action: () -> Void

  @State private var isArmed = false

  var body: some View {
    Button(isArmed ? confirmTitle : title) {
      guard isArmed else {
        arm()
        return
      }
      isArmed = false
      action()
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .tint(isArmed ? .red : nil)
  }

  private func arm() {
    isArmed = true
    Task {
      try? await Task.sleep(for: .seconds(3))
      isArmed = false
    }
  }
}
