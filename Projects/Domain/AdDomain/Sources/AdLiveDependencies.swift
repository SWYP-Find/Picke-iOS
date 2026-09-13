import AdDomainInterface
import ComposableArchitecture

extension FeedAdUseCaseDependency: DependencyKey {
  public static var liveValue: FeedAdInterface { FeedAdUseCaseImpl() }
}

extension FeedAdRepositoryDependency: DependencyKey {
  public static var liveValue: FeedAdInterface { FeedAdRepositoryImpl() }
}
