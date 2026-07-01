//
//  AnalyticsProvider.swift
//  UseCase
//
//  소셜 로그인 제공자(method). 도메인 SocialType 과 rawValue 일치.
//

import Foundation

public enum AnalyticsProvider: String, Sendable {
  case kakao
  case apple
  case google
}
