import AnalyticsService
import AnalyticsServiceInterface
import AppUpdateData
import AppUpdateDomain
import AudioPlayerService
import AuthData
import AuthDomain
import ComposableArchitecture
import DeviceService
import DeviceServiceInterface
import NetworkModule
import PickeStorage
import PickeStorageInterface
import WeaveDI

enum AppDependencyFactory {
  static let keychainManager: KeychainManaging = KeychainManager()

  @MainActor
  static func configure(_ values: inout DependencyValues) {
    values.keychainManager = keychainManager
    ChatFeatureFactory.configure(&values)
    ProfileFeatureFactory.configure(&values)
    AppServiceFactory.configure(&values)
  }

  /// Alamofire interceptor는 Store 수명 밖에서 실행되므로 제거 전까지 동일 인스턴스를 브리지한다.
  /// 화면 Reducer 의존성은 위 `configure(_:)`에서 명시적으로 주입한다.
  static func configureNetworkInfrastructure() {
    WeaveDI.builder
      .register { keychainManager }
      .register { AuthRepositoryImpl() as AuthInterface }
      .configure()

    OptimizedSessionManager.shared.configureNetworkSessions()
    KingfisherConfigurator.configureAuthorizedDownloader(
      keychainManager: keychainManager
    )
  }
}



private enum ChatFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.audioPlayer = AudioPlayerRepositoryImpl()
  }
}

private enum ProfileFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.deviceRepository = DeviceRepositoryImpl()
    values.deviceUseCase = DeviceUseCaseImpl()
  }
}


private enum AppServiceFactory {
  static func configure(_ values: inout DependencyValues) {
    values.analyticsUseCase = .liveValue
  }
}
