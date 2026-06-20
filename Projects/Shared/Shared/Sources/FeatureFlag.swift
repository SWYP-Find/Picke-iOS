//
//  FeatureFlag.swift
//  Shared
//
//  기능 토글 플래그 모음.
//  투표 기능 안정화 전까지 진입을 일시적으로 막기 위한 스위치.
//

import Foundation

/// 앱 전역 기능 토글.
///
/// 투표(사전/최종)가 안정화되면 `isVotingEnabled` 를 `true` 한 줄로 바꾸면 원복된다.
public enum FeatureFlag {
  /// 투표(사전투표/최종투표) 기능 활성화 여부.
  /// QA-38: 투표 안정화 전까지 일시 비활성화. 원복 시 `true` 로만 변경.
  public static let isVotingEnabled = false

  /// 투표 비활성화 시 사용자에게 노출할 안내 문구.
  public static let votingDisabledMessage = "투표 기능 준비 중입니다."
}
