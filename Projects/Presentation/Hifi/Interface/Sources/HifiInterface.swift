//
//  HifiInterface.swift
//  HifiInterface
//
//  Hifi(탐색) 피쳐의 public 계약(delegate).
//  구현(HifiCoordinator/HifiFeature/View)은 Hifi 타깃에 유지한다.
//

import Foundation

/// HifiFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum HifiDelegate: Equatable, Sendable {
  case openBattle(battleId: Int)
  /// 알림(종) 아이콘 → 알림받기 화면.
  case openNotification
}

public enum HifiInterface {}
