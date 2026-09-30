//
//  ClassCoordinatorView.swift
//  Picke
//

import ComposableArchitecture
import FeatureAssembly
import SwiftUI
import TCAFlow

public struct ClassCoordinatorView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>

  public init(store: StoreOf<ClassCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .intro(introStore):
        ClassIntroView(store: introStore)

      case let .topic(topicStore):
        ClassTopicView(store: topicStore)

      case let .recommend(recommendStore):
        ClassRecommendView(store: recommendStore)

      case let .setting(settingStore):
        ClassSettingView(store: settingStore)

      case let .share(shareStore):
        ClassShareView(store: shareStore)

      case let .join(joinStore):
        ClassJoinView(store: joinStore)

      case let .myClasses(myClassesStore):
        MyClassView(store: myClassesStore)

      case let .detail(detailStore):
        ClassDetailView(store: detailStore)

      case let .members(membersStore):
        ClassMemberView(store: membersStore)

      case let .chat(chatStore):
        ChatCoordinatorView(store: chatStore)
      }
    }
  }
}
