public enum ClassMemberCompletion: String, CaseIterable, Equatable, Sendable {
  case all = "전체"
  case noComment = "댓글 미작성"
  case noAfterVote = "사후 투표 미완료"
  case inProgress = "진행 중"
}
