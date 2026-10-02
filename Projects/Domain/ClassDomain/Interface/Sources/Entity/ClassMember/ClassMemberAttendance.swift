public enum ClassMemberAttendance: String, CaseIterable, Equatable, Sendable {
  case all = "전체"
  case changed = "입장 변화"
  case unchanged = "입장 유지"
  case inProgress = "진행 중"
}
