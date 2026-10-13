//
//  ClassCoordinatorView.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import FeatureAssembly
import SwiftUI
import TCAFlow

public struct ClassCoordinatorView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  public init(store: StoreOf<ClassCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .intro(introStore):
        ClassIntroView(store: introStore)

      case let .join(joinStore):
        ClassJoinView(store: joinStore)

      case let .startMethod(startMethodStore):
        ClassStartMethodView(store: startMethodStore)

      case let .topic(topicStore):
        ClassTopicView(store: topicStore)

      case let .recommend(recommendStore):
        ClassRecommendView(store: recommendStore)

      case let .setting(settingStore):
        ClassSettingView(store: settingStore)

      case let .share(shareStore):
        ClassShareView(store: shareStore)

      case let .ownerName(ownerNameStore):
        ClassJoinView(store: ownerNameStore)

      case let .myClasses(myClassesStore):
        MyClassView(store: myClassesStore)

      case let .detail(detailStore):
        ClassDetailView(store: detailStore)

      case let .members(membersStore):
        ClassMemberView(store: membersStore)

      case let .report(reportStore):
        ClassReportView(store: reportStore)

      case let .closedBattle(closedBattleStore):
        ClassClosedBattleView(store: closedBattleStore)

      case let .ownerDashboard(dashboardStore):
        ClassOwnerDashboardView(store: dashboardStore)

      case let .ownerMemberDetail(memberStore):
        ClassMemberDetailView(store: memberStore)

      case let .ownerReplyDetail(replyStore):
        ClassReplyDetailView(store: replyStore)

      case let .ownerFeedback(feedbackStore):
        ClassFeedbackComposeView(store: feedbackStore)

      case let .chat(chatStore):
        ClassChatCoordinatorView(store: chatStore, roomsByBattleID: store.chatRoomsByBattleID) { battleID in
          store.send(.view(.chatReportTapped(battleID: battleID)))
        }

      case let .aiVote(voteStore):
        ClassAIVoteView(store: voteStore)

      case let .aiChat(chatStore):
        ClassAIChatView(store: chatStore)
      }
    }
    .toolbar(store.showsTabBar ? .visible : .hidden, for: .tabBar)
    .sheet(item: $store.scope(state: \.deadlineEdit, action: \.deadlineEdit)) { editorStore in
      ClassDeadlineEditView(store: editorStore)
        .presentationDetents(
          dynamicTypeSize.isAccessibilitySize
            || editorStore.validationMessage != nil
            || editorStore.errorMessage != nil
            ? [.large] : [.height(360), .large]
        )
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(editorStore.isSaving)
    }
  }
}
