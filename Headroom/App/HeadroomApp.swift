import SwiftUI

struct HeadroomApp: App {
  @State private var monitor = MemoryMonitor()
  @State private var loginItem = LoginItem()

  var body: some Scene {
    MenuBarExtra {
      PanelView(monitor: monitor, loginItem: loginItem)
    } label: {
      MenuBarLabel(
        status: MenuBarStatus(memory: monitor.systemMemory, cpu: monitor.cpuUsage, battery: monitor.battery),
        pulseOpacity: monitor.menuBarPulse.opacity)
    }
    .menuBarExtraStyle(.window)

    Window("Headroom", id: WindowID.main) {
      PanelView(monitor: monitor, loginItem: loginItem)
    }
    .windowResizability(.contentSize)
    .defaultLaunchBehavior(LaunchOptions.opensWindowAtLaunch ? .presented : .suppressed)
  }
}
