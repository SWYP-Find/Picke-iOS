//
//  ClassCoordinatorView.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import FeatureAssembly
import PickeDesignKit
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

      case let .ticket(ticketStore):
        ClassTicketView(store: ticketStore)

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

      case let .myOpinions(opinionsStore):
        ClassMyOpinionsView(store: opinionsStore)

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
        aiVoteScreen(voteStore)

      case let .aiChat(chatStore):
        ClassAIChatView(store: chatStore)
      }
    }
    .allowsHitTesting(!store.isDeadlinePanelPresented)
    .accessibilityHidden(store.isDeadlinePanelPresented)
    .overlay {
      if let editorStore = store.scope(state: \.deadlineEdit, action: \.deadlineEdit.presented) {
        deadlinePanel(isDismissDisabled: editorStore.isSaving, onDismiss: {
          editorStore.send(.view(.backTapped))
        }) {
          ClassDeadlineEditView(store: editorStore)
        }
      } else if let selectionStore = store.scope(state: \.deadlineSelection, action: \.deadlineSelection.presented) {
        deadlinePanel(isDismissDisabled: false, onDismiss: {
          selectionStore.send(.view(.backTapped))
        }) {
          ClassDeadlineSelectionView(store: selectionStore)
        }
      }
    }
    .toolbar(.hidden, for: .tabBar)
  }
}

private extension ClassCoordinatorView {
  func aiVoteScreen(_ voteStore: StoreOf<ClassAIVoteFeature>) -> some View {
    let instanceID = voteStore.instanceID
    return ClassAIVoteView(store: voteStore) {
      // A popped view can appear again during the navigation transition.
      guard Self.isActiveAIVote(instanceID, in: store.routes) else { return }
      voteStore.send(.view(.onAppear))
    }
  }

  @ViewBuilder
  func deadlinePanel<Content: View>(
    isDismissDisabled: Bool,
    onDismiss: @escaping () -> Void,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture(perform: onDismiss)
          .allowsHitTesting(!isDismissDisabled)
          .accessibilityHidden(true)

        content()
          .frame(height: dynamicTypeSize.isAccessibilitySize ? max(300, geometry.size.height - 44) : 300)
          .padding(.bottom, geometry.safeAreaInsets.bottom)
          .background(.white)
          .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
          .overlay(alignment: .top) {
            Capsule()
              .fill(.gray50)
              .frame(width: 40, height: 4)
              .padding(.top, 12)
              .allowsHitTesting(false)
              .accessibilityHidden(true)
          }
          .accessibilityAddTraits(.isModal)
          .accessibilityAction(.escape, onDismiss)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .ignoresSafeArea(.container, edges: .bottom)
    }
  }
}

extension ClassCoordinatorView {
  static func isActiveAIVote(
    _ instanceID: UUID,
    in routes: [Route<ClassCoordinator.ClassScreen.State>]
  ) -> Bool {
    return routes.contains { route in
      guard case let .aiVote(vote) = route.screen else { return false }
      return vote.instanceID == instanceID
    }
  }
}
