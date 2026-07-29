//
//  ChatInterface.swift
//  ChatInterface
//

import Foundation

/// ChatCoordinator 진입 입력값.
public enum ChatRoute: Equatable, Sendable {
  /// 배틀 상세 투표 플로우 진입.
  case preVote(battleId: Int)
  /// 딥링크 알림에서 관점/답글 화면으로 바로 진입.
  case perspective(perspectiveId: Int, commentId: Int?)
  /// 이미 참여 완료한 배틀 — 관점(댓글) 화면으로 바로 진입.
  case comment(battleId: Int)
}

/// ChatRoomFeature 진입 입력값.
public struct ChatRoomRoute: Equatable, Sendable {
  public let battleId: Int

  public init(battleId: Int) {
    self.battleId = battleId
  }
}

/// ChatCoordinator 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum ChatDelegate: Equatable, Sendable {
  case dismiss
  case popToRoot
}

/// ChatRoomFeature 가 상위 coordinator 로 올려보내는 delegate 계약.
public enum ChatRoomDelegate: Equatable, Sendable {
  case dismiss
  case requestFinalVote(battleId: Int)
}

public enum ChatInterface {}
