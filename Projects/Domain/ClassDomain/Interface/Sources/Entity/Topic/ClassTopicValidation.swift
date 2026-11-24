import Foundation

public struct ClassTopicValidation: Equatable, Sendable {
  public struct Issue: Equatable, Sendable {
    public let field: String
    public let code: String
    public let message: String

    public init(field: String, code: String, message: String) {
      self.field = field
      self.code = code
      self.message = message
    }
  }

  public let valid: Bool
  public let issues: [Issue]
  public let validatedTopicVersionID: Int?
  public let remainingValidations: Int
  public let version: ClassTopicVersion?

  public init(
    valid: Bool,
    issues: [Issue],
    validatedTopicVersionID: Int?,
    remainingValidations: Int,
    version: ClassTopicVersion?
  ) {
    self.valid = valid
    self.issues = issues
    self.validatedTopicVersionID = validatedTopicVersionID
    self.remainingValidations = remainingValidations
    self.version = version
  }
}
