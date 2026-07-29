//
//  NoopAnalyticsUseCase.swift
//  DomainTesting
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
