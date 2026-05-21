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
}
