import SwiftUI

struct PanelFooterView: View {
  let statusMessage: String?
  let loginItem: LoginItem

  @Environment(\.openWindow) private var openWindow

  private static let activityMonitorURL = URL(
    fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let statusMessage {
        Text(statusMessage)
          .font(.caption)
      }
      HStack(spacing: 14) {
        OpenAtLoginToggle(loginItem: loginItem)
        Spacer()
        Button("Open in Window") {
          openWindow(id: WindowID.main)
          NSApp.activate()
        }
        Button("Activity Monitor") {
          NSWorkspace.shared.openApplication(
            at: Self.activityMonitorURL, configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil)
        }
        Button("Quit") { NSApp.terminate(nil) }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .buttonStyle(.borderless)
    }
  }
}
