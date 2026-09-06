//
//  AuthUseCaseInterface.swift
//  DomainInterface
//

import Foundation
import ComposableArchitecture

/// Auth 관련 비즈니스 로직 UseCase 를 위한 Interface 프로토콜
public protocol AuthUseCaseInterface: AuthInterface {}

/// Auth UseCase 의 DependencyKey 구조체
public enum AuthUseCaseDependency: TestDependencyKey {
  public static var testValue: AuthUseCaseInterface { MockAuthUseCase() }
}

public extension DependencyValues {
  var authUseCase: AuthUseCaseInterface {
    get { self[AuthUseCaseDependency.self] }
    set { self[AuthUseCaseDependency.self] = newValue }
  }
}
