//
//  BattleCoordinatorView.swift
//  Battle
//

import Foundation

import SwiftUI

import Chat
import ComposableArchitecture
import TCAFlow

public struct BattleCoordinatorView: View {
  @Bindable private var store: StoreOf<BattleCoordinator>

  public init(store: StoreOf<BattleCoordinator>) {
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
