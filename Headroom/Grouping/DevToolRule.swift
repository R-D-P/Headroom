struct DevToolRule: Sendable {
  let kind: DevToolKind
  let matches: @Sendable (ProcessRecord) -> Bool
}
