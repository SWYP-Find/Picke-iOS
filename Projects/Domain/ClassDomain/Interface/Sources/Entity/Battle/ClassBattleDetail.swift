import Foundation

public struct ClassBattleDetail: Equatable, Identifiable, Sendable {
  public let id: Int
  public let title: String
  public let summary: String
  public let thumbnailURL: URL?
  public let description: String
  public let shareURL: URL?
  public let userVoteStatus: String?
  public let currentStep: ClassBattleStep
  public let participantsCount: Int
  public let audioDuration: Int
  public let options: [ClassBattleOption]
  /// 카테고리 태그 이름(예: `철학`). 커스텀 배틀도 서버가 주제 카테고리를 태그로 붙인다.
  public let categoryTags: [String]

  public init(
    id: Int,
    title: String,
    summary: String,
    thumbnailURL: URL?,
    description: String,
    shareURL: URL?,
    userVoteStatus: String?,
    currentStep: ClassBattleStep,
    participantsCount: Int,
    audioDuration: Int,
    options: [ClassBattleOption],
    categoryTags: [String] = []
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.thumbnailURL = thumbnailURL
    self.description = description
    self.shareURL = shareURL
    self.userVoteStatus = userVoteStatus
    self.currentStep = currentStep
    self.participantsCount = participantsCount
    self.audioDuration = audioDuration
    self.options = options
    self.categoryTags = categoryTags
  }
}
