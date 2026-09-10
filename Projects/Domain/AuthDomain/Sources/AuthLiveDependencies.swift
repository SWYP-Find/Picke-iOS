//
//  AuthLiveDependencies.swift
//  AuthDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AuthDomainInterface
import ComposableArchitecture

extension AuthUseCaseDependency: DependencyKey {
  public static var liveValue: AuthUseCaseInterface { AuthUseCaseImpl() }
}

extension UnifiedOAuthUseCaseDependency: DependencyKey {
  public static var liveValue: UnifiedOAuthUseCaseInterface { UnifiedOAuthUseCase() }
}

extension AppleOAuthProviderDependency: DependencyKey {
  public static var liveValue: AppleOAuthProviderInterface { AppleOAuthProvider() }
}

extension GoogleOAuthProviderDependency: DependencyKey {
  public static var liveValue: GoogleOAuthProviderInterface { GoogleOAuthProvider() }
}

extension KakaoOAuthProviderDependency: DependencyKey {
  public static var liveValue: KakaoOAuthProviderInterface { KakaoOAuthProvider() }
}

extension AuthRepositoryDependency: DependencyKey {
  public static var liveValue: AuthInterface { AuthRepositoryImpl() }
}

extension AppleAuthRequestDependency: DependencyKey {
  public static var liveValue: AppleAuthRequestInterface { AppleLoginRepositoryImpl() }
}

extension AppleOAuthRepositoryDependencyKey: DependencyKey {
  public static var liveValue: AppleOAuthInterface { AppleOAuthRepositoryImpl() }
}

extension GoogleOAuthRepositoryDependencyKey: DependencyKey {
  public static var liveValue: GoogleOAuthInterface {
    GoogleOAuthRepositoryImpl(presentationContextProvider: AuthPresentationContextProvider())
  }
}

extension KakaoOAuthRepositoryDependencyKey: DependencyKey {
  public static var liveValue: KakaoOAuthInterface {
    KakaoOAuthRepository(presentationContextProvider: AuthPresentationContextProvider())
  }
}
