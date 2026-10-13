enum GroupAction: Sendable, Hashable {
  case restart
  case quit
  case stop

  var title: String {
    switch self {
    case .restart: "Restart"
    case .quit: "Quit"
    case .stop: "Stop"
    }
  }
}
