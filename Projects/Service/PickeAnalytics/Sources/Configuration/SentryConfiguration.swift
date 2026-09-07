//
//  SentryConfiguration.swift
//  PickeAnalytics
//

import Foundation

import LogMacro
@preconcurrency import Sentry

/// Sentry 기동과 런치 메트릭 전송.
enum SentryConfiguration {
  /// 가장 먼저 호출해 초기 크래시까지 포착한다.
  /// DSN·환경은 xcconfig → Info.plist 로 주입된 값을 읽는다(BASE_URL/MIXPANEL_TOKEN 과 동일 패턴).
  static func configure() {
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

      // 안정성 모니터링 활성화.
      // 앱 행(ANR): 완전 차단뿐 아니라 부분 차단(비블로킹)까지 리포트, 임계 2초.
      options.appHangTimeoutInterval = 2.0
      options.enableReportNonFullyBlockingAppHangs = true
      // 워치독 강제종료(OOM 등) 추적.
      options.enableWatchdogTerminationTracking = true
      // 세션(안정성/Crash-Free) 지표 자동 추적.
      options.enableAutoSessionTracking = true
      options.sessionTrackingIntervalMillis = 30000
      // 콜드 스타트 정확도(프리웜 구간 반영) + UI 인터랙션 자동 트랜잭션.
      options.enablePreWarmedAppStartTracing = true
      options.enableUserInteractionTracing = true
      // 크래시 순간 진행 중이던 트레이스를 보존해 유실 방지.
      options.enablePersistingTracesWhenCrashing = true

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
    emitLaunchMetrics(environment: environment)
  }

  /// 앱 실행 시 다양한 기기/런타임 메트릭을 환경 태깅해 전송한다(모든 빌드).
  /// 런치당 1회라 볼륨이 낮고, 카운트·게이지로 지표 유형을 다양화했다.
  private static func emitLaunchMetrics(environment: String) {
    let process = ProcessInfo.processInfo
    let attributes: [String: any SentryAttributeValue] = [
      "environment": environment,
      "source": "app_launch",
    ]
    let memoryMB = Double(process.physicalMemory) / 1_048_576.0

    // 카운트: 앱 실행 횟수(리텐션/DAU 보조 지표).
    SentrySDK.metrics.count(key: "app.launch.count", value: 1, attributes: attributes)
    // 게이지: 실행 시점 기기 리소스 스냅샷.
    SentrySDK.metrics.gauge(key: "app.device.memory_total_mb", value: memoryMB, attributes: attributes)
    SentrySDK.metrics.gauge(
      key: "app.device.processor_count",
      value: Double(process.activeProcessorCount),
      attributes: attributes
    )
    SentrySDK.metrics.gauge(
      key: "app.device.thermal_state",
      value: Double(process.thermalState.rawValue),
      attributes: attributes
    )
    SentrySDK.metrics.gauge(
      key: "app.device.low_power_mode",
      value: process.isLowPowerModeEnabled ? 1 : 0,
      attributes: attributes
    )
  }

  /// Sentry 온보딩 검증용 로그/메트릭. DEBUG(Stage) 빌드에서만 전송해 운영 데이터 오염을 막는다.
  private static func sendSentryVerificationTelemetry(environment: String) {
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
