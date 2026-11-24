import Foundation

public struct ClassTopicVersion: Equatable, Sendable {
  public struct Option: Equatable, Sendable {
    public let position: String
    public let label: String
    public let rationale: String
    public let philosopher: String?
    public let philosopherName: String?
    public let philosopherImageKey: String?

    public init(
      position: String,
      label: String,
      rationale: String,
      philosopher: String?,
      philosopherName: String?,
      philosopherImageKey: String?
    ) {
      self.position = position
      self.label = label
      self.rationale = rationale
      self.philosopher = philosopher
      self.philosopherName = philosopherName
      self.philosopherImageKey = philosopherImageKey
    }
  }

  public let id: Int
  public let draftID: Int
  public let versionNo: Int
  public let source: String
  public let question: String
  public let description: String
  public let category: String
  public let difficulty: String
  public let options: [Option]

  public init(
    id: Int,
    draftID: Int,
    versionNo: Int,
    source: String,
    question: String,
    description: String,
    category: String,
    difficulty: String,
    options: [Option]
  ) {
    self.id = id
    self.draftID = draftID
    self.versionNo = versionNo
    self.source = source
    self.question = question
    self.description = description
    self.category = category
    self.difficulty = difficulty
    self.options = options
  }
}
