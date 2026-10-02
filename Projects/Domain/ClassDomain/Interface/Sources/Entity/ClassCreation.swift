import Foundation

public struct ClassCreation: Equatable, Sendable {
  public var name: String
  public var deadline: Date
  public var battleId: Int
  public var allowsAnonymousOpinion: Bool
  public var requiresComment: Bool

  public init(
    name: String,
    deadline: Date,
    battleId: Int,
    allowsAnonymousOpinion: Bool,
    requiresComment: Bool
  ) {
    self.name = name
    self.deadline = deadline
    self.battleId = battleId
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
  }
}
