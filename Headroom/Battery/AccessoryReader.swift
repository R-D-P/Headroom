import Foundation
import IOKit

/// Finds what the Mac is charging or powering through its ports.
///
/// The power comes from the battery gauge's `PowerOutDetails`: one entry per port that's
/// supplying power, with the watts measured there. The names come from the USB devices, each
/// matched to its port through the `port-number` its USB controller carries.
enum AccessoryReader {
  /// Under this a port is supplying nothing worth listing unless a device is named on it.
  private static let idleWatts = 0.05

  static func read(powerOut: [RegistryProperties]) -> [PoweredAccessory] {
    guard !powerOut.isEmpty else { return [] }
    let names = deviceNamesByPort()
    return powerOut.compactMap { entry -> PoweredAccessory? in
      guard let port = entry.int("PortIndex"), let milliwatts = entry.int("Watts") else { return nil }
      let watts = Double(max(0, milliwatts)) / 1000
      let deviceNames = names[port] ?? []
      guard watts >= idleWatts || !deviceNames.isEmpty else { return nil }
      return PoweredAccessory(
        port: port, deviceNames: deviceNames, watts: watts,
        limitWatts: entry.int("PDPowermW").flatMap { $0 > 0 ? Double($0) / 1000 : nil })
    }
    .sorted { $0.port < $1.port }
  }

  private static func deviceNamesByPort() -> [Int: [String]] {
    var iterator: io_iterator_t = 0
    guard
      IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"), &iterator)
        == KERN_SUCCESS
    else { return [:] }
    defer { IOObjectRelease(iterator) }

    var names: [Int: [String]] = [:]
    while case let device = IOIteratorNext(iterator), device != 0 {
      defer { IOObjectRelease(device) }
      guard
        let name = IORegistryEntryCreateCFProperty(
          device, "USB Product Name" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String,
        // Held by the controller the device hangs off, however many hubs sit in between.
        let portNumber = IORegistryEntrySearchCFProperty(
          device, kIOServicePlane, "port-number" as CFString, kCFAllocatorDefault,
          IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? Data,
        portNumber.count >= 4
      else { continue }
      let port = Int(UInt32(littleEndian: portNumber.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }))
      let trimmed = name.trimmingCharacters(in: .whitespaces)
      if !trimmed.isEmpty, names[port]?.contains(trimmed) != true {
        names[port, default: []].append(trimmed)
      }
    }
    return names
  }
}
