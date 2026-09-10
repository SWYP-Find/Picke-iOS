//
//  HomeInterface.swift
//  HomeInterface
//

import Foundation

/// HomeFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum HomeDelegate: Equatable, Sendable {
  case presentPreVote(battleId: Int)
  /// "더보기" → 탐색 탭으로 이동.
  case moveToExplore
  /// 알림(종) 아이콘 → 알림받기 화면.
  case openNotification
}

public enum HomeInterface {}
