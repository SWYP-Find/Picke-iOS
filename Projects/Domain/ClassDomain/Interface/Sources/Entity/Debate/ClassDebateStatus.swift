public enum ClassDebateStatus: String, Equatable, Sendable {
  case generating = "GENERATING"
  case waitingUser = "WAITING_USER"
  case failed = "FAILED"
  case completed = "COMPLETED"
}
