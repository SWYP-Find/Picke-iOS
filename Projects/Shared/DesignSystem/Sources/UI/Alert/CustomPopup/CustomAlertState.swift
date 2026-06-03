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
      style: .confirmation
    )
  }

  static func deleteComment() -> CustomAlertState<CustomAlertAction> {
    CustomAlertState(
      title: "댓글을 삭제하시겠습니까?",
      confirmTitle: "삭제하기",
      cancelTitle: "뒤로가기",
      isDestructive: true,
      style: .confirmation
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
}
