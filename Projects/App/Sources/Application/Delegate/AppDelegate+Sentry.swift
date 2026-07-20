//
//  AppDelegate+Sentry.swift
//  Picke
//
//  Sentry 크래시/에러 리포팅 + 성능 트레이싱 + 프로파일링 초기화.
//

import Foundation
import LogMacro
@preconcurrency import Sentry

extension AppDelegate {
  /// 가장 먼저 호출해 초기 크래시까지 포착한다.
  /// DSN·환경은 xcconfig → Info.plist 로 주입된 값을 읽는다(BASE_URL/MIXPANEL_TOKEN 과 동일 패턴).
  func configureSentry() {
    let info = Bundle.main.infoDictionary
    // SENTRY_DSN 은 xcconfig 에서 스킴(https://)을 제외하고 저장 → 코드에서 붙인다.
    let dsnHost = (info?["SENTRY_DSN"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
    guard !dsnHost.isEmpty else {
      #logError("[Sentry] SENTRY_DSN 미설정 — 초기화 스킵")
      return
    }
    let environment = (info?["SENTRY_ENVIRONMENT"] as? String)?
      .trimmingCharacters(in: .whitespaces) ?? "production"

    SentrySDK.start { options in
      options.dsn = "https://\(dsnHost)"
      options.environment = environment

      #if DEBUG
        options.debug = true
      #else
        options.debug = false
      #endif

      options.releaseName = (info?["CFBundleShortVersionString"] as? String).map {
        "picke-ios@\($0)+\((info?["CFBundleVersion"] as? String) ?? "")"
      }

      // 구조화 로그.
      options.enableLogs = true
      options.enableMetrics = true

      // 성능 트레이싱 + 프로파일링(트레이싱에 종속).
      options.tracesSampleRate = 0.2
      options.configureProfiling = {
        $0.lifecycle = .trace
        $0.sessionSampleRate = 1.0
      }

      options.enableTimeToFullDisplayTracing = true
      options.enableMetricKit = true
      options.swiftAsyncStacktraces = true

      options.enableSwizzling = true
      options.enableAutoPerformanceTracing = true
      options.enableNetworkTracking = true
      options.enableNetworkBreadcrumbs = true

      options.enableCaptureFailedRequests = true
      options.failedRequestStatusCodes = [
        HttpStatusCodeRange(
          min: 400,
          max: 599
        ),
      ]

      // 크래시 컨텍스트 첨부.
      options.attachScreenshot = true
      options.attachViewHierarchy = false

      // Session Replay는 별도 렌더링/인코딩 큐(io.sentry.session-replay.processing)를 사용한다.
      // SwiftUI + Mixpanel Session Replay와 동시에 켜면 디버깅 중 해당 큐에서 멈추는 케이스가 있어 비활성화한다.
      options.sessionReplay.maskAllText = true
      options.sessionReplay.maskAllImages = true
      options.sessionReplay.sessionSampleRate = 0.0
      options.sessionReplay.onErrorSampleRate = 0.0
    }

    sendSentryVerificationTelemetry(environment: environment)
  }

  /// Sentry 온보딩 검증용 로그/메트릭. DEBUG(Stage) 빌드에서만 전송해 운영 데이터 오염을 막는다.
  func sendSentryVerificationTelemetry(environment: String) {
    #if DEBUG
      let logAttributes: [String: Any] = [
        "log_type": "test",
        "environment": environment,
        "source": "app_launch",
      ]
      let metricAttributes: [String: any SentryAttributeValue] = [
        "log_type": "test",
        "environment": environment,
        "source": "app_launch",
      ]

      SentrySDK.logger.info(
        "Sending a test info log",
        attributes: logAttributes
      )
      SentrySDK.logger.warn(
        "Sending a test warning log",
        attributes: logAttributes
      )

      SentrySDK.metrics.count(
        key: "app.launch.count",
        value: 1,
        attributes: metricAttributes
      )
      SentrySDK.metrics.gauge(
        key: "app.launch.queue_depth",
        value: 1.0,
        attributes: metricAttributes
      )
      SentrySDK.metrics.distribution(
        key: "app.launch.verification_time",
        value: 1.0,
        unit: .millisecond,
        attributes: metricAttributes
      )
    #endif
  }
}
