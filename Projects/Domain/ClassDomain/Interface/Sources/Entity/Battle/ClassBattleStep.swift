public enum ClassBattleStep: String, Equatable, Sendable {
  case none = "NONE"
  case preVote = "PRE_VOTE"
  case ttsListening = "TTS_LISTENING"
  case postVote = "POST_VOTE"
  case completed = "COMPLETED"
}
