//
//  AnalyticsEvent.swift
//  UseCase
//
//  Mixpanel 트래킹 이벤트 정의 — 카테고리 + 속성값으로 구분(무료 플랜 한도 절약).
//  설계: docs/analytics-mixpanel-design.md
//

import Foundation

public enum AnalyticsEvent: Sendable {
  /// 소셜 가입 완료 및 메인 진입 시.
  case signUp(method: AnalyticsProvider)
  /// 배틀 각 단계 완료 시 (pre_vote / audio_end / post_vote).
  case battleStep(BattleStepData)
  /// 리포트 조회 시. (공유는 shareAction 으로 통일)
  case reportAction(ReportActionData)
  /// 댓글 등록 성공 시.
  case communityAction(CommunityActionData)
  /// 보상형 광고 시청 완료 시.
  case adRevenue(placement: AdPlacement)

  // MARK: 확장 (설계: analytics-mixpanel-design.md)

  /// 온보딩 퍼널 단계.
  case onboardingStep(step: OnboardingStep, provider: AnalyticsProvider?)
  /// 포인트 적립/차감.
  case pointAction(PointActionData)
  /// 알림 진입/모두읽음/항목탭.
  case notificationAction(NotificationActionData)
  /// 공유(리포트/배틀/최종투표) — 모든 공유 통일.
  case shareAction(ShareActionData)
  /// 화면 진입 (전체 화면).
  case screenView(screen: AnalyticsScreen, referrer: AnalyticsScreen?)
  /// 홈/콘텐츠 카드 탭.
  case contentAction(ContentActionData)
  /// 버튼 탭 전반.
  case uiAction(action: AnalyticsButton, screen: AnalyticsScreen)
  /// (Tier3, 선택) 재생 조작.
  case playbackAction(action: PlaybackAction, contentID: String)
  /// (Tier3, 선택) 미세 상호작용.
  case engagementAction(action: EngagementAction, targetID: String)
}
