public enum ClassOwnerOpinionFilter: String, CaseIterable, Hashable, Sendable {
  case all = "전체"
  case recommended = "추천순"
  case replies = "대댓글 많은순"
  case inProgress = "진행 중 10"
}
