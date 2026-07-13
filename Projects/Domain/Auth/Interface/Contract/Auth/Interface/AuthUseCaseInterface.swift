//
//  AuthUseCaseInterface.swift
//  DomainInterface
//
//  Auth UseCase 인터페이스 + 의존성 등록.
//  구현(AuthUseCaseImpl)은 UseCase 모듈에 유지하고 DI 로 주입한다.
//

import Foundation
import WeaveDI

/// Auth 관련 비즈니스 로직 UseCase 를 위한 Interface 프로토콜
public protocol AuthUseCaseInterface: AuthInterface {}

/// Auth UseCase 의 DependencyKey 구조체
public struct AuthUseCaseDependency: DependencyKey {
  public static var liveValue: AuthUseCaseInterface {
    return UnifiedDI.resolve(AuthUseCaseInterface.self) ?? DefaultAuthUseCaseImpl()
  }

  public static var testValue: AuthUseCaseInterface {
    return UnifiedDI.resolve(AuthUseCaseInterface.self) ?? DefaultAuthUseCaseImpl()
  }

  public static var previewValue: AuthUseCaseInterface = liveValue
}

public extension DependencyValues {
  var authUseCase: AuthUseCaseInterface {
    get { self[AuthUseCaseDependency.self] }
    set { self[AuthUseCaseDependency.self] = newValue }
  }
}
