import ComposableArchitecture
import Foundation

public protocol ClassTicketInterface: Sendable {
  func previewTicket(code: String) async throws -> ClassTicketPreview
  func registerTicket(code: String) async throws -> ClassTicket
  func fetchMyTicket() async throws -> ClassTicket
}

public enum ClassTicketRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassTicketInterface {
    MockClassRepository()
  }
}

public enum ClassTicketUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassTicketInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classTicketRepository: any ClassTicketInterface {
    get { self[ClassTicketRepositoryDependency.self] }
    set { self[ClassTicketRepositoryDependency.self] = newValue }
  }

  var classTicketUseCase: any ClassTicketInterface {
    get { self[ClassTicketUseCaseDependency.self] }
    set { self[ClassTicketUseCaseDependency.self] = newValue }
  }
}
