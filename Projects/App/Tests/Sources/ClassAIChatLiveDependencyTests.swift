import ComposableArchitecture
import DomainAssembly
@testable import Picke
import Testing

struct ClassAIChatLiveDependencyTests {
  @Test
  func 앱의_live_컨텍스트는_실제_대화_UseCase를_등록한다() {
    let isLive = withDependencies {
      $0.context = .live
    } operation: {
      @Dependency(\.classAIChatUseCase) var useCase
      return useCase is ClassAIChatUseCaseImpl
    }

    #expect(isLive)
  }
}
