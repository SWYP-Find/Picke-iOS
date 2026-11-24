import Foundation

public struct ClassTicket: Equatable, Sendable {
  public enum Status: String, Equatable, Sendable {
    case active = "ACTIVE"
    case expired = "EXPIRED"
  }

  public let id: Int
  public let capacity: Int
  public let status: Status
  public let activatedAt: Date
  public let expiresAt: Date
  public let remainingDays: Int
  public let readGraceEndsAt: Date

  public init(
    id: Int,
    capacity: Int,
    status: Status,
    activatedAt: Date,
    expiresAt: Date,
    remainingDays: Int,
    readGraceEndsAt: Date
  ) {
    self.id = id
    self.capacity = capacity
    self.status = status
    self.activatedAt = activatedAt
    self.expiresAt = expiresAt
    self.remainingDays = remainingDays
    self.readGraceEndsAt = readGraceEndsAt
  }
}
