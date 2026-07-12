//
//  Dependencies+OAuth.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

import Dependencies
import AuthDomainInterface
import Foundation

// MARK: - Apple OAuth Provider Registration

public extension AppleOAuthProviderDependency {
  static var liveValue: AppleOAuthProviderInterface {
    AppleOAuthProvider()
  }
}

// MARK: - Google OAuth Provider Registration

public extension GoogleOAuthProviderDependency {
  static var liveValue: GoogleOAuthProviderInterface {
    GoogleOAuthProvider()
  }
}

// MARK: - Kakao OAuth Provider Registration

public extension KakaoOAuthProviderDependency {
  static var liveValue: KakaoOAuthProviderInterface {
    KakaoOAuthProvider()
  }
}
