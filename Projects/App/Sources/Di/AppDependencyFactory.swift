import AnalyticsService
import AnalyticsServiceInterface
import AppUpdateData
import AppUpdateDomain
import AudioPlayerService
import AuthData
import AuthDomain
import BattleData
import BattleDomain
import CommentData
import CommentDomain
import ComposableArchitecture
import DeviceService
import DeviceServiceInterface
import HomeData
import HomeDomain
import NetworkModule
import NotificationData
import NotificationDomain
import PerspectiveData
import PerspectiveDomain
import PickeStorage
import PickeStorageInterface
import ProfileData
import ProfileDomain
import SearchData
import SearchDomain
import WeaveDI

enum AppDependencyFactory {
  static let keychainManager: KeychainManaging = KeychainManager()

  @MainActor
  static func configure(_ values: inout DependencyValues) {
    values.keychainManager = keychainManager
    AuthFeatureFactory.configure(&values)
    HomeFeatureFactory.configure(&values)
    ChatFeatureFactory.configure(&values)
    ProfileFeatureFactory.configure(&values)
    SearchFeatureFactory.configure(&values)
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

private enum AuthFeatureFactory {
  @MainActor
  static func configure(_ values: inout DependencyValues) {
    values.authRepository = AuthRepositoryImpl()
    values.authUseCase = AuthUseCaseImpl()
    values.appleManger = AppleLoginRepositoryImpl()
    values.appleOAuthRepository = AppleOAuthRepositoryImpl()
    values.googleOAuthRepository = GoogleOAuthRepositoryImpl(
      presentationContextProvider: AppPresentationContextProvider()
    )
    values.kakaoOAuthRepository = KakaoOAuthRepository(
      presentationContextProvider: AppPresentationContextProvider()
    )
    values.appleOAuthProvider = AppleOAuthProvider()
    values.googleOAuthProvider = GoogleOAuthProvider()
    values.kakaoOAuthProvider = KakaoOAuthProvider()
    values.unifiedOAuthUseCase = UnifiedOAuthUseCase()
  }
}

private enum HomeFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.homeRepository = HomeRepositoryImpl()
    values.homeUseCase = HomeUseCaseImpl()
    values.notificationRepository = NotificationRepositoryImpl()
    values.notificationUseCase = NotificationUseCaseImpl()
  }
}

private enum ChatFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.battleRepository = BattleRepositoryImpl()
    values.battleUseCase = BattleUseCaseImpl()
    values.commentRepository = CommentRepositoryImpl()
    values.commentUseCase = CommentUseCaseImpl()
    values.perspectiveRepository = PerspectiveRepositoryImpl()
    values.perspectiveUseCase = PerspectiveUseCaseImpl()
    values.audioPlayer = AudioPlayerRepositoryImpl()
  }
}

private enum ProfileFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.profileRepository = ProfileRepositoryImpl()
    values.profileUseCase = ProfileUseCaseImpl()
    values.deviceRepository = DeviceRepositoryImpl()
    values.deviceUseCase = DeviceUseCaseImpl()
  }
}

private enum SearchFeatureFactory {
  static func configure(_ values: inout DependencyValues) {
    values.searchRepository = SearchRepositoryImpl()
    values.searchUseCase = SearchUseCaseImpl()
  }
}

private enum AppServiceFactory {
  static func configure(_ values: inout DependencyValues) {
    values.analyticsUseCase = .liveValue
    values.appUpdateRepository = AppUpdateRepositoryImpl()
    values.appUpdateUseCase = AppUpdateUseCaseImpl()
  }
}
