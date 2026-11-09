//
//  HomeInterface.swift
//  HomeInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

/// HomeFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum HomeDelegate: Equatable, Sendable {
  case presentPreVote(battleId: Int)
  /// 알림(종) 아이콘 → 알림받기 화면.
  case openNotification
}

public enum HomeInterface {}
