//
//  OnboardingStep.swift
//  UseCase
//

import Foundation

public enum OnboardingStep: String, Sendable {
  case splash
  case loginShown = "login_shown"
  case kakaoStart = "kakao_start"
  case termsShown = "terms_shown"
  case termsAgreed = "terms_agreed"
  case permissionAsked = "permission_asked"
  case homeEntered = "home_entered"
}
