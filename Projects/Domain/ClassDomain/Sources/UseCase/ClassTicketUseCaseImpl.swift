import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassTicketUseCaseImpl: ClassTicketInterface {
  @Dependency(\.classTicketRepository) private var repository

  public init() {}

  public func preview(code: String) async throws -> ClassTicketPreview {
    try await repository.preview(code: code)
  }

  public func register(code: String) async throws -> ClassTicket {
    try await repository.register(code: code)
  }

  public func fetchMyTicket() async throws -> ClassTicket {
    try await repository.fetchMyTicket()
  }
}
