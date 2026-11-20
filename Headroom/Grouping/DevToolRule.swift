struct DevToolRule: Sendable {
  let kind: DevToolKind
  let matches: @Sendable (DevToolClassifier.Program) -> Bool
}
