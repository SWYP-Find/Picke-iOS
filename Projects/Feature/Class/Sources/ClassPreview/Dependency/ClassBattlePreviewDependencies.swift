import AudioPlayerServiceInterface
import BattleDomainInterface
import ComposableArchitecture
import PickeAnalyticsInterface

/// 클래스의 목 채팅 의존성과 별도로 미리 듣기에 사용할 실제 서비스들을 전달한다.
public struct ClassBattlePreviewDependencies: Sendable {
  public var battleUseCase: any BattleInterface
  public var audioPlayer: any AudioPlayerInterface
  public var analyticsUseCase: AnalyticsUseCase

  public init(
    battleUseCase: any BattleInterface,
    audioPlayer: any AudioPlayerInterface,
    analyticsUseCase: AnalyticsUseCase
  ) {
    self.battleUseCase = battleUseCase
    self.audioPlayer = audioPlayer
    self.analyticsUseCase = analyticsUseCase
  }
}

extension ClassBattlePreviewDependencies: TestDependencyKey {
  public static var testValue: Self {
    Self(
      battleUseCase: BattleUseCaseDependency.testValue,
      audioPlayer: AudioPlayerDependency.testValue,
      analyticsUseCase: AnalyticsUseCase.testValue
    )
  }
}

public extension DependencyValues {
  var classBattlePreviewDependencies: ClassBattlePreviewDependencies {
    get { self[ClassBattlePreviewDependencies.self] }
    set { self[ClassBattlePreviewDependencies.self] = newValue }
  }
}
