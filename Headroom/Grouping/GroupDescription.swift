/// Everything about a row except its processes and total, which come from its members.
struct GroupDescription {
  let kind: GroupKind
  let title: String
  var details: [String] = []
  var explanation: String?
  var isOrphaned = false
  var startedByClaudeSession: String?
  var isSelf = false
}
