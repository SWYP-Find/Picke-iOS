//
//  AppBattleCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import Presentation
import TCAFlow

public struct AppBattleCoordinatorView: View {
  @Bindable private var store: StoreOf<AppBattleCoordinator>

  public init(store: StoreOf<AppBattleCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .battle(battleStore):
        BattleView(store: battleStore)
      case let .chatRoom(chatRoomStore):
        ChatRoomView(store: chatRoomStore)
      case let .chat(chatStore):
        ChatCoordinatorView(store: chatStore)
      }
    }
  }
}
