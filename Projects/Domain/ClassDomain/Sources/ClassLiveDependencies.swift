import ClassDomainInterface
import ComposableArchitecture

extension ClassUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassUseCaseImpl()
  }
}

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    #if DEBUG
      DebugClassRepository.shared
    #else
      ClassRepositoryImpl()
    #endif
  }
}

extension ClassMockRepositoryDependency: DependencyKey {
  public static var liveValue: MockClassRepository? {
    #if DEBUG
      DebugClassRepository.shared
    #else
      nil
    #endif
  }
}

#if DEBUG
  private enum DebugClassRepository {
    static let shared = MockClassRepository()
  }
#endif
