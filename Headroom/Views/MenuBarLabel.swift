import SwiftUI

/// Free memory, the number you glance at to know whether there's room for more.
struct MenuBarLabel: View {
  let memory: SystemMemory?

  var body: some View {
    Label(title, systemImage: symbolName)
      .labelStyle(.titleAndIcon)
  }

  private var title: String {
    memory.map { ByteFormatting.compact($0.freeBytes) } ?? "–"
  }

  private var symbolName: String {
    guard let memory, memory.pressure != .normal else { return "memorychip" }
    return "exclamationmark.triangle.fill"
  }
}
