import Foundation

public struct ClassBattleOption: Equatable, Identifiable, Sendable {
  public let id: Int
  public let label: String?
  public let title: String
  public let stance: String
  public let representative: String
  public let imageURL: URL?

  public init(id: Int, label: String?, title: String, stance: String, representative: String, imageURL: URL?) {
    self.id = id
    self.label = label
    self.title = title
    self.stance = stance
    self.representative = representative
    self.imageURL = imageURL
  }
}
