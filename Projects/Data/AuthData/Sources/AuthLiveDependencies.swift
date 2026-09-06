//
//  AuthLiveDependencies.swift
//  AuthData
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AuthDomainInterface
import ComposableArchitecture

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
