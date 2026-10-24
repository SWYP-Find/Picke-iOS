import ComposableArchitecture
import Foundation

public protocol ClassTicketInterface: Sendable {
  func preview(code: String) async throws -> ClassTicketPreview
  func register(code: String) async throws -> ClassTicket
  func fetchMyTicket() async throws -> ClassTicket
}

public enum ClassTicketRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassTicketInterface { UnimplementedClassTicketInterface() }
}

public enum ClassTicketUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassTicketInterface { UnimplementedClassTicketInterface() }
}

private struct UnimplementedClassTicketInterface: ClassTicketInterface {
  func preview(code _: String) async throws -> ClassTicketPreview {
    throw ClassTicketError.network("이용권 코드 확인을 사용할 수 없어요.")
  }

  func register(code _: String) async throws -> ClassTicket {
    throw ClassTicketError.network("이용권 등록을 사용할 수 없어요.")
  }

  func fetchMyTicket() async throws -> ClassTicket {
    throw ClassTicketError.network("내 이용권 조회를 사용할 수 없어요.")
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
