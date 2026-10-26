import Foundation

public struct ClassPerspectiveReceipt: Equatable, Sendable {
  public let id: Int
  public let status: String
  public let createdAt: Date

  public init(
    id: Int,
    status: String,
    createdAt: Date
  ) {
    self.id = id
    self.status = status
    self.createdAt = createdAt
  }
}
