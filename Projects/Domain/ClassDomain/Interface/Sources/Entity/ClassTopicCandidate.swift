import Foundation

public struct ClassTopicCandidate: Equatable, Identifiable, Sendable {
  public struct Option: Equatable, Sendable {
    public let label: String
    public let rationale: String
    public let philosopher: String?

    public init(label: String, rationale: String, philosopher: String?) {
      self.label = label
      self.rationale = rationale
      self.philosopher = philosopher
    }
  }

  public let id: Int
  public let question: String
  public let description: String
  public let category: String
  public let difficulty: String
  public let options: [Option]

  public init(
    id: Int,
    question: String,
    description: String,
    category: String,
    difficulty: String,
    options: [Option]
  ) {
    self.id = id
    self.question = question
    self.description = description
    self.category = category
    self.difficulty = difficulty
    self.options = options
  }
}
