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
    options: [ClassBattleOption]
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
  }
}
