//
//  HifiInterface.swift
//  HifiInterface
//

import Foundation

/// HifiFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum HifiDelegate: Equatable, Sendable {
  case openBattle(battleId: Int)
  /// 알림(종) 아이콘 → 알림받기 화면.
  case openNotification
}

public enum HifiInterface {}
