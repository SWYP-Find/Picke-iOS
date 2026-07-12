//
//  NoopAnalyticsUseCase.swift
//  DomainTesting
//
//  Mixpanel 을 건드리지 않는 no-op AnalyticsUseCase.
//  테스트에서 analyticsUseCase 의존성을 안전하게 대체한다.
//

import UseCase

public extension AnalyticsUseCase {
  static let noop = AnalyticsUseCase(
    registerBaseProperties: {},
    identify: { _, _ in },
    track: { _ in },
    reset: {}
  )
}
