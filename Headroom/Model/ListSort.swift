/// What the RAM and CPU lists are ordered by. Stored as text, so each tab remembers its own.
struct ListSort: Equatable, RawRepresentable {
  enum Key: String, CaseIterable, Identifiable {
    case memory
    case cpu

    var id: Self { self }

    var title: String {
      switch self {
      case .memory: "RAM"
      case .cpu: "CPU"
      }
    }
  }

  var key: Key
  var ascending = false

  init(key: Key, ascending: Bool = false) {
    self.key = key
    self.ascending = ascending
  }

  init?(rawValue: String) {
    let parts = rawValue.split(separator: ":")
    guard parts.count == 2, let key = Key(rawValue: String(parts[0])) else { return nil }
    self.init(key: key, ascending: parts[1] == "asc")
  }

  var rawValue: String { "\(key.rawValue):\(ascending ? "asc" : "desc")" }

  /// Orders rows by the chosen value, breaking ties by title so rows don't jump between refreshes.
  func ordered<Row>(_ rows: [Row], value: (Row) -> Double, title: (Row) -> String) -> [Row] {
    rows.sorted { first, second in
      let firstValue = value(first)
      let secondValue = value(second)
      guard firstValue == secondValue else {
        return ascending ? firstValue < secondValue : firstValue > secondValue
      }
      return title(first).localizedStandardCompare(title(second)) == .orderedAscending
    }
  }
}
