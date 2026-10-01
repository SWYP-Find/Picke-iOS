import ClassDomainInterface
import ComposableArchitecture

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface { ClassRepositoryImpl() }
}
