public enum ClassMemberSort: String, CaseIterable, Equatable, Sendable {
  case name = "이름순"
  case comments = "댓글 많은순"
  case replies = "대댓글 많은순"
  case recommendations = "추천순"
}
