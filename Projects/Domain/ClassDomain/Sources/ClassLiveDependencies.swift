import ClassDomainInterface
import ComposableArchitecture

extension ClassUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassUseCaseImpl()
  }
}

extension ClassAIChatUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassAIChatInterface {
    ClassAIChatUseCaseImpl()
  }
}

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassMockRepositoryStorage.shared
  }
}

extension ClassMockRepositoryDependency: DependencyKey {
  public static var liveValue: MockClassRepository? {
    ClassMockRepositoryStorage.shared
  }
}

private enum ClassMockRepositoryStorage {
  static let shared = MockClassRepository()
}
