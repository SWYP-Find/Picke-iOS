//
//  AppleAuthRequestInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 12/26/25.
//

import Foundation
import AuthenticationServices
import ComposableArchitecture

public protocol AppleAuthRequestInterface: Sendable {
  func prepare(_ request: ASAuthorizationAppleIDRequest) -> String
}

///// OAuth Repository의 DependencyKey 구조체
public enum AppleAuthRequestDependency: TestDependencyKey {
  public static var testValue: AppleAuthRequestInterface { MockAppleAuthRequest() }
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
  var appleManger: AppleAuthRequestInterface {
    get { self[AppleAuthRequestDependency.self] }
    set { self[AppleAuthRequestDependency.self] = newValue }
  }
}

