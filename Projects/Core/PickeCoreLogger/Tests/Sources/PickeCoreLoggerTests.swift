//
//  PickeCoreLoggerTests.swift
//  PickeCoreLogger
//
//  Copyright © 2026 Picke. All rights reserved.
//

import OSLog
import Testing

@testable import PickeCoreLogger

@Suite("PickeCoreLogger")
struct PickeCoreLoggerTests {
  @Test("카테고리는 OSLog category 문자열 계약을 유지한다")
  func categoriesExposeExpectedRawValues() {
    let rawValues = PickeLogCategory.allCases.map(\.rawValue)

    #expect(rawValues == [
      "app",
      "network",
      "auth",
      "navigation",
      "storage",
      "ui",
      "battle"
    ])
  }

  @Test("로그 레벨은 심각도 순서대로 정렬된다")
  func logLevelsSortBySeverity() {
    #expect(PickeLogLevel.allCases.sorted() == [
      .debug,
      .info,
      .notice,
      .error,
      .fault
    ])
  }

  @Test("로그 레벨은 OSLogType으로 매핑된다")
  func logLevelsMapToOSLogTypes() {
    #expect(PickeLogLevel.debug.osLogType == .debug)
    #expect(PickeLogLevel.info.osLogType == .info)
    #expect(PickeLogLevel.notice.osLogType == .default)
    #expect(PickeLogLevel.error.osLogType == .error)
    #expect(PickeLogLevel.fault.osLogType == .fault)
  }

  @Test("DEBUG 빌드의 기본 최소 레벨은 debug다")
  func debugBuildMinimumLevelStartsAtDebug() {
    #if DEBUG
    #expect(PickeLogger.defaultMinimumLevel == .debug)
    #else
    #expect(PickeLogger.defaultMinimumLevel == .notice)
    #endif
  }

  @Test("공개 로그 API는 파일 위치 메타데이터와 함께 호출할 수 있다")
  func publicLogAPIsAcceptExplicitCallsiteMetadata() {
    PickeLogger.debug("debug", category: .app, fileID: "Module/File.swift", function: "test()", line: 10)
    PickeLogger.info("info", category: .network, fileID: "Module/File.swift", function: "test()", line: 11)
    PickeLogger.notice("notice", category: .auth, fileID: "Module/File.swift", function: "test()", line: 12)
    PickeLogger.error("error", category: .storage, fileID: "Module/File.swift", function: "test()", line: 13)
    PickeLogger.fault("fault", category: .battle, fileID: "Module/File.swift", function: "test()", line: 14)

    #expect(Bool(true))
  }
}
