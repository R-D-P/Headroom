import SwiftUI

/// The background jobs inside macOS that are worth naming when they're busy.
enum MacOSSubsystem: String, Sendable, CaseIterable {
  case spotlight
  case photos
  case backup
  case iCloud
  case softwareUpdate
  case security
  case windowServer
  case other
  /// Not a real set of processes: the CPU use no listed process accounts for.
  case unattributed

  private static let processNames: [MacOSSubsystem: Set<String>] = [
    .spotlight: [
      "mds", "mds_stores", "mdworker", "mdworker_shared", "mdsync", "mdbulkimport", "corespotlightd",
      "Spotlight", "spotlightknowledged",
    ],
    .photos: ["photoanalysisd", "mediaanalysisd", "photolibraryd", "mediaanalysisd-access"],
    .backup: ["backupd", "backupd-helper"],
    .iCloud: ["bird", "cloudd", "fileproviderd", "cloudphotod"],
    .softwareUpdate: ["softwareupdated", "mobileassetd", "SoftwareUpdateNotificationManager"],
    .security: ["XProtect", "XprotectService", "XProtectRemediatorBehavioralRules", "syspolicyd", "MRT"],
    .windowServer: ["WindowServer"],
  ]

  static func of(executablePath: String) -> MacOSSubsystem {
    let name = (executablePath as NSString).lastPathComponent
    return processNames.first { $0.value.contains(name) }?.key ?? .other
  }

  var title: String {
    switch self {
    case .spotlight: "Spotlight indexing"
    case .photos: "Photos and media analysis"
    case .backup: "Time Machine"
    case .iCloud: "iCloud sync"
    case .softwareUpdate: "Software updates"
    case .security: "Security scans"
    case .windowServer: "WindowServer"
    case .other: "Other macOS services"
    case .unattributed: "Kernel and short-lived processes"
    }
  }

  var explanation: String {
    switch self {
    case .spotlight:
      "Indexing your files so search can find them. Normal for a while after a restart, an update or copying lots of files; it settles down on its own."
    case .photos: "Scanning photos and videos for people, objects and text. Mostly runs while the Mac is idle."
    case .backup: "Backing up to your Time Machine disk."
    case .iCloud: "Syncing files and data with iCloud."
    case .softwareUpdate: "Downloading or preparing macOS updates."
    case .security: "macOS checking apps and files for malware."
    case .windowServer: "Draws everything on screen. Busier with animations, many windows or external displays."
    case .other: "Everything else macOS runs in the background. Can't be quit."
    case .unattributed:
      "The macOS kernel, plus processes that started and finished between two readings (compilers, scripts, git)."
    }
  }

  var symbolName: String {
    switch self {
    case .spotlight: "magnifyingglass"
    case .photos: "photo.on.rectangle"
    case .backup: "clock.arrow.circlepath"
    case .iCloud: "icloud"
    case .softwareUpdate: "arrow.down.circle"
    case .security: "checkmark.shield"
    case .windowServer: "macwindow.on.rectangle"
    case .other: "apple.logo"
    case .unattributed: "bolt.horizontal"
    }
  }

  var tint: Color {
    switch self {
    case .spotlight: .blue
    case .photos: .yellow
    case .backup: .green
    case .iCloud: .cyan
    case .softwareUpdate: .indigo
    case .security: .mint
    case .windowServer, .other, .unattributed: .gray
    }
  }
}
