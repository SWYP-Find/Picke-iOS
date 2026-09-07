import PickeAnalytics
import PickeAnalyticsInterface
import AudioPlayerService
import ComposableArchitecture
import CoreAssembly
import DeviceService
import DeviceServiceInterface
import DomainAssembly
import PickeAuthInterface
import PickeStorageInterface
import ServiceAssembly

enum AppDependencyFactory {
  /// 네트워크·인증·저장소 live 구현은 ServiceAssembly 가 단일 출처로 조립한다.
  static var secureStorage: any SecureStorage { StorageAssembly.secureStorage() }
  /// 로그인 여부·토큰 판정은 PickeAuth 가 단독으로 책임진다. App 은 저장소를 직접 열지 않는다.
  static var authService: any AuthService { NetworkContainer.authService }

  @MainActor
  static func configure(_ values: inout DependencyValues) {
    ServiceDependencyAssembly.register(into: &values)
    ChatFeatureFactory.configure(&values)
    ProfileFeatureFactory.configure(&values)
    AppServiceFactory.configure(&values)
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
