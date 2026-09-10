//
//  PickeAnalyticsConfiguration.swift
//  PickeAnalytics
//

/// 관측 SDK 기동 진입점. 순서에 의미가 있다.
///
/// Sentry 를 가장 먼저 올려야 이후 초기화 중 발생한 크래시까지 포착된다.
public enum PickeAnalyticsConfiguration {
  public static func configure() {
    SentryConfiguration.configure()
    MixpanelConfiguration.configure()
  }
}
