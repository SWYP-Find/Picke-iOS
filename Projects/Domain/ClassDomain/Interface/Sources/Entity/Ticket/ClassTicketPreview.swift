import Foundation

public struct ClassTicketPreview: Equatable, Sendable {
  public let capacity: Int
  public let registerBy: Date
  public let usageMonths: Int
  public let registeredByMe: Bool

  public init(
    capacity: Int,
    registerBy: Date,
    usageMonths: Int,
    registeredByMe: Bool
  ) {
    self.capacity = capacity
    self.registerBy = registerBy
    self.usageMonths = usageMonths
    self.registeredByMe = registeredByMe
  }
}
