//
//  AdPlacement.swift
//  UseCase
//

import Foundation

/// 광고가 놓인 자리. ad_revenue(리워드 시청 완료)와 ad_click(광고 클릭)이 함께 쓴다.
public enum AdPlacement: String, Sendable {
  /// 충전소 리워드 광고. 이미 쌓인 ad_revenue 데이터와 값이 끊기지 않도록 표기를 그대로 둔다.
  case charge = "충전소"
  /// 홈 피드 네이티브.
  case home
  /// 큐레이션 리스트 최상단 네이티브.
  case curation
  /// 마이페이지 하단 네이티브.
  case mypage
  /// 탐색(Hifi) 카드 사이 배너.
  case explore
  /// 앱 시작 전면 팝업.
  case appStart = "app_start"
}
