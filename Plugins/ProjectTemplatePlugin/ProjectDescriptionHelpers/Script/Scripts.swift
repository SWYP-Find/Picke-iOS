//
//  Scripts.swift
//  MyPlugin
//
//  Created by 서원지 on 1/6/24.
//

import Foundation
import ProjectDescription

public enum Scripts {
  public static let swiftLintScript: String = """
  if test -d "/opt/homebrew/bin/"; then
      PATH="/opt/homebrew/bin/:${PATH}"
  fi

  export PATH

  if which swiftlint > /dev/null; then
      swiftlint
  else
      echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  """

  public static let FirebaseCrashlytics: String = """
   ROOT_DIR=\(ProcessInfo.processInfo.environment["TUIST_ROOT_DIR"] ?? "")
      "${ROOT_DIR}/Tuist/Dependencies/SwiftPackageManager/.build/checkouts/firebase-ios-sdk/Crashlytics/run"
  """

  /// Sentry dSYM 업로드 — sentry-cli 설치 + 인증 토큰(.sentryclirc / SENTRY_AUTH_TOKEN)이 있을 때만 실행.
  /// 없으면 경고만 남기고 조용히 스킵하므로 로컬/CI 어디서든 빌드를 막지 않는다.
  public static let sentryDSYMUpload: String = """
  if which sentry-cli >/dev/null 2>&1; then
      export SENTRY_ORG=picke
      export SENTRY_PROJECT=apple-ios
      sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" || true
  else
      echo "warning: sentry-cli 미설치 — dSYM 업로드 스킵 (brew install getsentry/tools/sentry-cli)"
  fi
  """
}
