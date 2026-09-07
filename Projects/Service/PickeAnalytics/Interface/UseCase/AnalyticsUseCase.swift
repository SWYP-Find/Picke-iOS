//
//  AnalyticsUseCase.swift
//  PickeAnalytics
//

import Foundation

import ComposableArchitecture

// MARK: - UseCase

/// 유저 액션 트래킹 계약.
public struct AnalyticsUseCase: Sendable {
  /// 앱 시작 시 공통 슈퍼 프로퍼티(os_type/app_version/build) 등록.
  public var registerBaseProperties: @Sendable () -> Void
  /// 로그인 성공 직후 유저 고유 ID 연결 + 로그인 슈퍼/유저 프로퍼티 설정.
  public var identify: @Sendable (_ userID: String, _ method: String?) -> Void
  /// 핵심 퍼널 이벤트 트래킹.
  public var track: @Sendable (_ event: AnalyticsEvent) -> Void
  /// 로그아웃/탈퇴 시 계정 분리(reset) + 공통 프로퍼티 재등록.
  public var reset: @Sendable () -> Void

  public init(
    registerBaseProperties: @escaping @Sendable () -> Void,
    identify: @escaping @Sendable (_ userID: String, _ method: String?) -> Void,
    track: @escaping @Sendable (_ event: AnalyticsEvent) -> Void,
    reset: @escaping @Sendable () -> Void
  ) {
    self.registerBaseProperties = registerBaseProperties
    self.identify = identify
    self.track = track
    self.reset = reset
  }
}

/// 테스트/프리뷰 기본값은 인터페이스가 갖는다. `liveValue` 는 구현 모듈이 `DependencyKey` 로 채운다
extension AnalyticsUseCase: TestDependencyKey {
  public static let testValue = AnalyticsUseCase(
    registerBaseProperties: {},
    identify: { _, _ in },
    track: { _ in },
    reset: {}
  )
  public static let previewValue = testValue
}

public extension DependencyValues {
  var analyticsUseCase: AnalyticsUseCase {
    get { self[AnalyticsUseCase.self] }
    set { self[AnalyticsUseCase.self] = newValue }
  }
}
