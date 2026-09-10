//
//  GoogleOAuthInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation
import ComposableArchitecture

public protocol GoogleOAuthInterface: Sendable {
  func signIn() async throws -> GoogleOAuthPayload
}

public enum GoogleOAuthRepositoryDependencyKey: TestDependencyKey {
  public static var testValue: GoogleOAuthInterface { MockGoogleOAuthRepository() }
}

public extension DependencyValues {
  var googleOAuthRepository:  GoogleOAuthInterface {
    get { self[GoogleOAuthRepositoryDependencyKey.self] }
    set { self[GoogleOAuthRepositoryDependencyKey.self] = newValue }
  }
}

