//
//  CustomAlertState.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import SwiftUI

import PickeDesignKit

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
  /// 본문 + 취소(왼쪽 밝은)·확인(오른쪽 primary), 취소 문구가 비면 확인 1개.
  case notice
  /// 본문 + 확인(왼쪽 밝은)·취소(오른쪽 primary). 배경 탭(취소)이 "안내만 닫기"여야 할 때 쓴다.
  case noticeReversed
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
      cancelTitle: "댓글보러가기",
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

  // MARK: - 클래스 이용권 안내 (Android 문구)

  static func classTicketRequired() -> CustomAlertState<CustomAlertAction> {
    notice(
      "클래스를 열려면 이용권이 필요해요\n클래스 기능을 먼저 알아보세요!",
      confirmTitle: "뒤로가기"
    )
  }

  static func classTicketExpired() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "사용 중이던 이용권이 종료되었습니다\n새로운 이용권을 등록해주세요!",
      confirmTitle: "등록하기",
      cancelTitle: "뒤로가기",
      style: .notice
    )
  }

  /// 뒤로가기=확인(화면 닫기), 등록하기=취소(안내만 닫기). 배경 탭도 안내만 닫는다.
  static func ticketAlreadyRegistered() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "이미 등록된 이용권입니다\n다른 이용권을 등록해주세요!",
      confirmTitle: "뒤로가기",
      cancelTitle: "등록하기",
      style: .noticeReversed
    )
  }

  static func ticketInvalidCode() -> CustomAlertState<CustomAlertAction> {
    notice("코드 번호를 다시 확인해주세요!")
  }

  static func ticketRegistrationExpired() -> CustomAlertState<CustomAlertAction> {
    notice("해당 이용권은 등록기간이 만료되었습니다")
  }

  static func ticketRegisterFailed() -> CustomAlertState<CustomAlertAction> {
    notice("코드 등록이 완료되지 않았습니다\n네트워크 확인 후 한 번 더 시도해주세요")
  }

  static func ticketAlreadyActive() -> CustomAlertState<CustomAlertAction> {
    notice("이미 사용 중인 이용권이 있어요\n만료 후 등록할 수 있어요")
  }

  private static func notice(
    _ title: String,
    confirmTitle: String = "확인"
  ) -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: title,
      confirmTitle: confirmTitle,
      cancelTitle: "",
      style: .notice
    )
  }
}
