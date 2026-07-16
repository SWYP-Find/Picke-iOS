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
  if ! which sentry-cli >/dev/null 2>&1; then
      echo "warning: sentry-cli 미설치 — dSYM 업로드 스킵 (brew install getsentry/tools/sentry-cli)"
      exit 0
  fi

  if [ -z "${SENTRY_AUTH_TOKEN:-}" ] && [ ! -f "$HOME/.sentryclirc" ]; then
      echo "warning: Sentry 인증 정보 없음 — dSYM 업로드 스킵 (SENTRY_AUTH_TOKEN 또는 ~/.sentryclirc 필요)"
      exit 0
  fi

  if [ -z "${DWARF_DSYM_FOLDER_PATH:-}" ] || [ ! -d "$DWARF_DSYM_FOLDER_PATH" ]; then
      echo "warning: dSYM 경로 없음 — dSYM 업로드 스킵"
      exit 0
  fi

  export SENTRY_ORG="${SENTRY_ORG:-picke}"
  export SENTRY_PROJECT="${SENTRY_PROJECT:-picke-ios}"

  upload_output="$(sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1)"
  upload_status=$?

  if [ "$upload_status" -ne 0 ]; then
      echo "warning: Sentry dSYM 업로드 실패 — archive는 계속 진행합니다"
      printf '%s\n' "$upload_output" | sed 's/^error:/warning:/'
      exit 0
  fi

  printf '%s\n' "$upload_output"
  """
  /// Sentry Size Analysis — App Store용 xcarchive를 sentry-cli로 업로드한다.
  /// SENTRY_AUTH_TOKEN이 없거나 sentry-cli가 없으면 로컬 빌드는 막지 않는다.
  public static let sentrySizeAnalysisUpload: String = """
  if ! which sentry-cli >/dev/null 2>&1; then
      echo "warning: sentry-cli 미설치 — Size Analysis 업로드 스킵 (brew install getsentry/tools/sentry-cli)"
      exit 0
  fi

  if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
      echo "warning: SENTRY_AUTH_TOKEN 미설정 — Size Analysis 업로드 스킵"
      exit 0
  fi

  export SENTRY_ORG="${SENTRY_ORG:-picke}"
  export SENTRY_PROJECT="${SENTRY_PROJECT:-picke-ios}"
  ARCHIVE_PATH="${SENTRY_ARCHIVE_PATH:-${ARCHIVE_PATH:-}}"

  if [ -z "$ARCHIVE_PATH" ] || [ ! -d "$ARCHIVE_PATH" ]; then
      echo "warning: xcarchive 경로 없음 — SENTRY_ARCHIVE_PATH 또는 ARCHIVE_PATH 지정 필요"
      exit 0
  fi

  sentry-cli build upload "$ARCHIVE_PATH" \
      --org "$SENTRY_ORG" \
      --project "$SENTRY_PROJECT" || true
  """

}
