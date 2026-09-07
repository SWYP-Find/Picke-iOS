import PickeAnalytics
import PickeAnalyticsInterface
import AudioPlayerService
import ComposableArchitecture
import CoreAssembly
import DeviceService
import DeviceServiceInterface
import DomainAssembly
import PickeStorageInterface
import ServiceAssembly

enum AppDependencyFactory {
  /// 네트워크·인증·저장소 live 구현은 ServiceAssembly 가 단일 출처로 조립한다.
  static var secureStorage: any SecureStorage { StorageAssembly.secureStorage() }

  @MainActor
  static func configure(_ values: inout DependencyValues) {
    ServiceDependencyAssembly.register(into: &values)
    ChatFeatureFactory.configure(&values)
    ProfileFeatureFactory.configure(&values)
    AppServiceFactory.configure(&values)
  }

  /// Store 수명 밖에서 도는 인프라(이미지 다운로더)를 앱 시작 시 한 번 설정한다.
  /// 화면 Reducer 의존성은 위 `configure(_:)`에서 명시적으로 주입한다.
  static func configureNetworkInfrastructure() {
    KingfisherConfigurator.configureAuthorizedDownloader(
      storage: secureStorage
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
