//
//  AuthInterface.swift
//  AuthInterface
//
//  Auth 피쳐의 public 계약(route/input model + delegate).
//  구현(LoginFeature/OnBoardingFeature/AuthCoordinator/View)은 Auth 타깃에 유지한다.
//

import Foundation

/// AuthCoordinator 진입 입력값.
public enum AuthRoute: Equatable, Sendable {
  case login
}

/// LoginFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum LoginDelegate: Equatable, Sendable {
  case presentOnboarding
  case presentMainTab
  case presentTermsWeb(urlString: String)
}

/// OnBoardingFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum OnBoardingDelegate: Equatable, Sendable {
  case presentMainTab
}

/// AuthCoordinator 가 App 조립자에 올려보내는 delegate 계약.
public enum AuthDelegate: Equatable, Sendable {
  case presentMainTab
}

public enum AuthInterface {}
