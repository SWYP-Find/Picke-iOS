//
//  CustomAlertState.swift
//  DesignSystem
//

import ComposableArchitecture
import SwiftUI

@ObservableState
public struct CustomAlertState<Action>: Equatable {
  public let title: String
  public let message: String
  public let confirmTitle: String
  public let cancelTitle: String
  public let isDestructive: Bool
  public let style: CustomAlertStyle

  public init(
    title: String,
    message: String = "",
    confirmTitle: String = "확인",
    cancelTitle: String = "취소",
    isDestructive: Bool = false,
    style: CustomAlertStyle = .confirmation
  ) {
    self.title = title
    self.message = message
    self.confirmTitle = confirmTitle
    self.cancelTitle = cancelTitle
    self.isDestructive = isDestructive
    self.style = style
  }
}

public enum CustomAlertStyle: Equatable {
  case confirmation
  case finalVote
  case report
  case alreadyWatched
  case deleteConfirm
  case logout
  case withdraw
  case suggestTopic
}

@CasePathable
public enum CustomAlertAction: Equatable {
  case confirmTapped
  case cancelTapped
}

@Reducer
public struct CustomConfirmAlert {
  public init() {}

  public var body: some Reducer<CustomAlertState<CustomAlertAction>, CustomAlertAction> {
    EmptyReducer()
  }
}

public extension CustomAlertState where Action == CustomAlertAction {
  static func alert(
    title: String,
    message: String = "",
    confirmTitle: String = "확인",
    cancelTitle: String = "취소",
    isDestructive: Bool = false
  ) -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: title,
      message: message,
      confirmTitle: confirmTitle,
      cancelTitle: cancelTitle,
      isDestructive: isDestructive,
      style: .confirmation
    )
  }

  static func finalVote() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "최종투표하고 투표 결과를 보시겠습니까?",
      confirmTitle: "최종투표하기",
      cancelTitle: "다시 들어볼래요",
      style: .finalVote
    )
  }

  static func deletePerspective() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "관점을 삭제하시겠습니까?",
      confirmTitle: "삭제하기",
      cancelTitle: "뒤로가기",
      isDestructive: true,
      style: .deleteConfirm
    )
  }

  static func deleteComment() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "댓글을 삭제하시겠습니까?",
      confirmTitle: "삭제하기",
      cancelTitle: "뒤로가기",
      isDestructive: true,
      style: .deleteConfirm
    )
  }

  static func report() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "",
      confirmTitle: "신고",
      cancelTitle: "",
      isDestructive: true,
      style: .report
    )
  }

  static func alreadyWatched() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "다시 콘텐츠를 시청하시겠습니까?",
      message: "이미 참여 완료한 배틀입니다.\n기존 내역이 삭제되고\n다시 처음부터 진행됩니다.",
      confirmTitle: "다시",
      cancelTitle: "취소",
      isDestructive: true,
      style: .alreadyWatched
    )
  }

  /// 로그아웃 확인 — 확정(로그아웃)=왼쪽 밝은 버튼, 취소(유지)=오른쪽 primary 버튼.
  static func logout() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "로그아웃 시 원활한 이용이 어려울 수 있습니다.\n그럼에도 로그아웃하시겠습니까?",
      confirmTitle: "네, 로그아웃합니다",
      cancelTitle: "그대로 있을게요",
      isDestructive: true,
      style: .logout
    )
  }

  /// 회원 탈퇴 확인 — 확정(탈퇴)=왼쪽 밝은 버튼, 취소(유지)=오른쪽 primary 버튼.
  static func withdraw() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "탈퇴 시 지금까지의 이용기록이 영구 삭제 됩니다.\n그럼에도 탈퇴하시겠습니까?",
      confirmTitle: "네, 탈퇴합니다",
      cancelTitle: "뒤로가기",
      isDestructive: true,
      style: .withdraw
    )
  }

  /// 주제 제안 — 제안하기=오른쪽 primary 버튼, 뒤로가기=왼쪽 밝은 버튼.
  static func suggestTopic() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "나만의 배틀을 제안해주세요",
      message: "-30P를 사용해 원하는 주제를 제안하고,\n채택되면 +100P를 돌려받아요.",
      confirmTitle: "제안하기",
      cancelTitle: "뒤로가기",
      style: .suggestTopic
    )
  }
}
