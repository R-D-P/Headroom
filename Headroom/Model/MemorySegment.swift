import SwiftUI

/// The parts of the memory bar, in the order they are drawn.
enum MemorySegment: CaseIterable, Identifiable {
  case apps
  case wired
  case compressed
  case cached
  case unused

  var id: Self { self }

  var title: String {
    switch self {
    case .apps: "Apps"
    case .wired: "macOS (wired)"
    case .compressed: "Compressed"
    case .cached: "Cached files"
    case .unused: "Unused"
    }
  }

  var explanation: String {
    switch self {
    case .apps: "In active use by apps and dev tools"
    case .wired: "Kernel and drivers. Can't be freed"
    case .compressed: "Idle memory macOS has squeezed"
    case .cached: "Recent files, freed when needed"
    case .unused: "Holding nothing at all"
    }
  }

  var color: Color {
    switch self {
    case .apps: .blue
    case .wired: .gray
    case .compressed: .purple
    case .cached: .teal.opacity(0.45)
    case .unused: .secondary.opacity(0.2)
    }
  }

  func bytes(in memory: SystemMemory) -> UInt64 {
    switch self {
    case .apps: memory.appBytes
    case .wired: memory.wiredBytes
    case .compressed: memory.compressedBytes
    case .cached: memory.cachedBytes
    case .unused: memory.unusedBytes
    }
  }
}
