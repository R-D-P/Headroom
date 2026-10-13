import SwiftUI

struct OpenAtLoginToggle: View {
  let loginItem: LoginItem

  var body: some View {
    if loginItem.needsApproval {
      Button("Allow open at login…") { loginItem.openSystemSettings() }
    } else {
      Toggle(
        "Open at login",
        isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) })
      )
      .toggleStyle(.checkbox)
      .controlSize(.small)
    }
  }
}
