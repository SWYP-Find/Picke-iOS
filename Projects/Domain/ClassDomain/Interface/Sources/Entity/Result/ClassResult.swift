import Foundation

public struct ClassResult: Equatable, Sendable {
  public let classID: Int
  public let closed: Bool
  public let closeAt: Date
  public let stats: ClassResultStats
  public let myReportState: String?
  public let insightState: String?

  public init(
    classID: Int,
    closed: Bool,
    closeAt: Date,
    stats: ClassResultStats,
    myReportState: String?,
    insightState: String?
  ) {
    self.classID = classID
    self.closed = closed
    self.closeAt = closeAt
    self.stats = stats
    self.myReportState = myReportState
    self.insightState = insightState
  }
}

/// Android `ClassReportState` — 인사이트·내 리포트 응답의 생성 상태. 알 수 없는 값은 PENDING.
public enum ClassResultReportState: String, Equatable, Sendable {
  case beforeClose = "BEFORE_CLOSE"
  case notEligible = "NOT_ELIGIBLE"
  case pending = "PENDING"
  case generating = "GENERATING"
  case succeeded = "SUCCEEDED"
  case limited = "LIMITED"
  case failed = "FAILED"

  public static func from(_ value: String?) -> Self {
    value.flatMap(Self.init(rawValue:)) ?? .pending
  }
}

/// Android `ClassResultInsightBoard` — 상태를 오류로 바꾸지 않고 그대로 담는다.
public struct ClassResultInsightBoard: Equatable, Sendable {
  public let state: ClassResultReportState
  public let insightText: String?
  public let retryable: Bool

  public init(state: ClassResultReportState, insightText: String?, retryable: Bool) {
    self.state = state
    self.insightText = insightText
    self.retryable = retryable
  }
}

/// Android `ClassResultMyReportBoard` — 내 리포트 탭에 필요한 값만 상태와 함께 담는다.
public struct ClassResultMyReportBoard: Equatable, Sendable {
  public let state: ClassResultReportState
  public let preOptionTitle: String?
  public let postOptionTitle: String?
  public let perspectiveCount: Int
  public let commentCount: Int
  /// 피드백 본문이 없으면 nil.
  public let feedback: Feedback?

  public struct Feedback: Equatable, Sendable {
    public let judgmentBasis: String
    public let strength: String?
    public let nextFocus: String?
    public let nextQuestion: String
    public let coverage: String?

    public init(
      judgmentBasis: String,
      strength: String?,
      nextFocus: String?,
      nextQuestion: String,
      coverage: String?
    ) {
      self.judgmentBasis = judgmentBasis
      self.strength = strength
      self.nextFocus = nextFocus
      self.nextQuestion = nextQuestion
      self.coverage = coverage
    }
  }

  public init(
    state: ClassResultReportState,
    preOptionTitle: String?,
    postOptionTitle: String?,
    perspectiveCount: Int,
    commentCount: Int,
    feedback: Feedback?
  ) {
    self.state = state
    self.preOptionTitle = preOptionTitle
    self.postOptionTitle = postOptionTitle
    self.perspectiveCount = perspectiveCount
    self.commentCount = commentCount
    self.feedback = feedback
  }
}
