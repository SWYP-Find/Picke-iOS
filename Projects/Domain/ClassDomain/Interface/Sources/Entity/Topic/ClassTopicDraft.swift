import Foundation

public struct ClassTopicDraft: Equatable, Sendable {
  public let id: Int
  public let topicSeed: String
  public let difficulty: String
  public let categories: [String]
  public let suggestStatus: String
  public let clarificationMessage: String?
  public let batchNo: Int
  public let remainingSuggestions: Int
  public let remainingValidations: Int
  public let candidates: [ClassTopicCandidate]
  public let latestVersion: ClassTopicVersion?

  public init(
    id: Int,
    topicSeed: String,
    difficulty: String,
    categories: [String],
    suggestStatus: String,
    clarificationMessage: String?,
    batchNo: Int,
    remainingSuggestions: Int,
    remainingValidations: Int,
    candidates: [ClassTopicCandidate],
    latestVersion: ClassTopicVersion?
  ) {
    self.id = id
    self.topicSeed = topicSeed
    self.difficulty = difficulty
    self.categories = categories
    self.suggestStatus = suggestStatus
    self.clarificationMessage = clarificationMessage
    self.batchNo = batchNo
    self.remainingSuggestions = remainingSuggestions
    self.remainingValidations = remainingValidations
    self.candidates = candidates
    self.latestVersion = latestVersion
  }
}
