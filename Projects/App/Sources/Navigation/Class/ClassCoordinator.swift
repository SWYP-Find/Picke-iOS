//
//  ClassCoordinator.swift
//  Picke
//

import AudioPlayerServiceInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeAnalyticsInterface
import PickeCoreUtility
import TCAFlow

@FlowCoordinator(screen: "ClassScreen", navigation: true)
public struct ClassCoordinator {
  @Dependency(\.classMockRepository) private var classMockRepository
  @Dependency(\.classMockChatSession) private var classMockChatSession

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<ClassScreen.State>]
    public var usesAIQuestions = false

    public init() {
      routes = [.root(.intro(.init()), embedInNavigationView: true)]
    }

    /// 모달을 닫으면 해당 화면의 탭바를 다시 보여준다.
    public var showsTabBar: Bool {
      switch routes.last?.screen {
      case let .detail(detail)?:
        return detail.modal == nil && detail.customAlert == nil
      case let .members(members)?:
        return members.filter == nil && members.editName == nil && members.customAlert == nil
      case let .myClasses(myClasses)?:
        return myClasses.modal == nil && myClasses.customAlert == nil
      case let .ownerDashboard(dashboard)?:
        return dashboard.management == nil
      case .report?:
        return true
      default:
        return false
      }
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<ClassScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {
    case membersLoaded(ClassRoom, [ClassMember], Int)
    case membersFailed(Int, String)
    case memberMutationCompleted(ClassRoom, [ClassMember])
    case memberMutationFailed(Int, String)
    case mockBattleRegistered(roomID: Int, battleID: Int)
  }

  public enum NavigationAction: Equatable {}

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)
    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)
    case let .inner(innerAction):
      handleInnerAction(state: &state, action: innerAction)
    case .async, .navigation:
      .none
    }
  }
}

private extension ClassCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ClassScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .intro(.delegate(.joined(room, nickname: _)))):
      state.routes.push(.detail(.init(room: room)))
      return .none

    case .routeAction(_, action: .intro(.delegate(.myClasses))):
      state.routes.push(.myClasses(.init()))
      return .none

    case .routeAction(_, action: .intro(.delegate(.create))):
      state.routes.push(.startMethod(.init()))
      return .none

    case .routeAction(_, action: .startMethod(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .startMethod(.delegate(.existingContentSelected))):
      state.usesAIQuestions = false
      state.routes.push(.topic(.init()))
      return .none

    case .routeAction(_, action: .startMethod(.delegate(.ownTopicSelected))):
      state.usesAIQuestions = true
      state.routes.push(.topic(.init()))
      return .none

    case .routeAction(_, action: .topic(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .topic(.delegate(.search(filter)))):
      state.routes.push(.recommend(.init(
        filter: filter,
        mode: state.usesAIQuestions ? .aiQuestions : .existingContent
      )))
      return .none

    case .routeAction(_, action: .recommend(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .recommend(.delegate(.select(battle)))):
      state.routes.push(.setting(.init(battle: battle)))
      return .none

    case let .routeAction(_, action: .recommend(.delegate(.selectAIQuestion(question, filter)))):
      state.routes.push(.setting(.init(aiQuestion: question, filter: filter)))
      return .none

    case .routeAction(_, action: .setting(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .setting(.delegate(.created(room)))):
      state.routes.push(.share(.init(room: room)))
      return .none

    case .routeAction(_, action: .share(.delegate(.dismiss))):
      return .send(.view(.backToRootAction))

    case let .routeAction(_, action: .share(.delegate(.enterClass(room)))):
      state.routes.goBackToRoot()
      state.routes.push(.detail(.init(room: room)))
      return .none

    case .routeAction(_, action: .join(.delegate(.dismiss))),
         .routeAction(_, action: .myClasses(.delegate(.dismiss))),
         .routeAction(_, action: .detail(.delegate(.dismiss))),
         .routeAction(_, action: .members(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .join(.delegate(.joined(room, nickname: _)))),
         let .routeAction(_, action: .myClasses(.delegate(.openRoom(room)))):
      state.routes.push(.detail(.init(room: room)))
      return .none

    case let .routeAction(_, action: .myClasses(.delegate(.openInformation(room)))):
      var detail = ClassDetailFeature.State(room: room)
      detail.modal = .init(kind: .deadline)
      state.routes.push(.detail(detail))
      return .none

    case let .routeAction(_, action: .detail(.delegate(.openMembers(room)))):
      state.routes.push(.members(.init(room: room)))
      guard let classMockRepository else { return .none }
      return .run { send in
        do {
          let members = try await classMockRepository.fetchMembers(roomID: room.id)
          let currentMemberID = try await classMockRepository.currentMemberID(roomID: room.id)
          await send(.inner(.membersLoaded(room, members, currentMemberID)))
        } catch {
          await send(.inner(.membersFailed(room.id, error.localizedDescription)))
        }
      }

    case let .routeAction(
      _,
      action: .members(.delegate(.removeMember(roomID: roomID, memberID: memberID, currentMemberID: currentMemberID)))
    ):
      guard let classMockRepository else {
        return .send(.inner(.memberMutationFailed(roomID, "멤버 변경을 사용할 수 없어요.")))
      }
      return .run { send in
        do {
          let room = try await classMockRepository.removeMember(
            roomID: roomID,
            memberID: memberID,
            currentMemberID: currentMemberID
          )
          let members = try await classMockRepository.fetchMembers(roomID: roomID)
          await send(.inner(.memberMutationCompleted(room, members)))
        } catch {
          await send(.inner(.memberMutationFailed(roomID, error.localizedDescription)))
        }
      }

    case let .routeAction(
      _,
      action: .members(.delegate(.updateDisplayName(
        roomID: roomID,
        memberID: memberID,
        currentMemberID: currentMemberID,
        name: name
      )))
    ):
      guard let classMockRepository else {
        return .send(.inner(.memberMutationFailed(roomID, "이름 변경을 사용할 수 없어요.")))
      }
      return .run { send in
        do {
          _ = try await classMockRepository.updateDisplayName(
            roomID: roomID,
            memberID: memberID,
            currentMemberID: currentMemberID,
            name: name
          )
          let members = try await classMockRepository.fetchMembers(roomID: roomID)
          let rooms = try await classMockRepository.fetchMyClasses()
          guard let room = rooms.first(where: { $0.id == roomID }) else {
            throw ClassError.invalidCode
          }
          await send(.inner(.memberMutationCompleted(room, members)))
        } catch {
          await send(.inner(.memberMutationFailed(roomID, error.localizedDescription)))
        }
      }

    case let .routeAction(_, action: .detail(.delegate(.openBattle(room)))):
      guard classMockRepository != nil else { return .none }
      return .run { [classMockChatSession] send in
        let battleID = await classMockChatSession.register(room: room)
        await send(.inner(.mockBattleRegistered(roomID: room.id, battleID: battleID)))
      }

    case let .routeAction(_, action: .detail(.delegate(.openClosedBattle(room)))):
      state.routes.push(.closedBattle(.init(room: room)))
      return .none

    case .routeAction(_, action: .closedBattle(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .detail(.delegate(.openReport(room)))),
         let .routeAction(_, action: .closedBattle(.delegate(.openReport(room)))):
      if room.role == .owner {
        let dashboard: ClassOwnerDashboardFeature.State = room == ClassRoom.mocks[0]
          ? .preview(room: room)
          : .init(room: room)
        state.routes.push(.ownerDashboard(dashboard))
      } else {
        state.routes.push(.report(.init(room: room)))
      }
      return .none

    case .routeAction(_, action: .report(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .ownerDashboard(.delegate(.dismiss))),
         .routeAction(_, action: .ownerMemberDetail(.delegate(.dismiss))),
         .routeAction(_, action: .ownerReplyDetail(.delegate(.dismiss))),
         .routeAction(_, action: .ownerFeedback(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .ownerDashboard(.delegate(.editClass))):
      return returnToClassDetail(state: &state, action: .deadlineTapped)

    case .routeAction(_, action: .ownerDashboard(.delegate(.deleteClass))):
      return returnToClassDetail(state: &state, action: .deleteTapped)

    case let .routeAction(_, action: .ownerDashboard(.delegate(.openMemberDetail(member)))):
      guard case let .ownerDashboard(dashboard)? = state.routes.last?.screen else { return .none }
      state.routes.push(.ownerMemberDetail(.init(room: dashboard.room, member: member)))
      return .none

    case let .routeAction(_, action: .ownerDashboard(.delegate(.openReplyDetail(opinion)))):
      guard case let .ownerDashboard(dashboard)? = state.routes.last?.screen else { return .none }
      state.routes.push(.ownerReplyDetail(.init(room: dashboard.room, opinion: opinion)))
      return .none

    case let .routeAction(_, action: .ownerDashboard(.delegate(.openFeedback(member)))):
      guard case let .ownerDashboard(dashboard)? = state.routes.last?.screen else { return .none }
      state.routes.push(.ownerFeedback(.init(room: dashboard.room, memberName: member.name)))
      return .none

    case let .routeAction(_, action: .ownerMemberDetail(.delegate(.commentSelected(opinion)))):
      guard case let .ownerMemberDetail(member)? = state.routes.last?.screen else { return .none }
      state.routes.push(.ownerReplyDetail(.init(room: member.room, opinion: opinion)))
      return .none

    case .routeAction(_, action: .ownerMemberDetail(.delegate(.feedbackSelected))):
      guard case let .ownerMemberDetail(member)? = state.routes.last?.screen else { return .none }
      state.routes.push(.ownerFeedback(.init(room: member.room, memberName: member.member.name)))
      return .none

    case .routeAction(_, action: .ownerFeedback(.delegate(.submitted))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.popToRoot))):
      return .send(.view(.backToRootAction))

    case .routeAction(_, action: .aiVote(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .aiVote(.delegate(.voteSubmitted(battleID)))):
      guard case .aiVote? = state.routes.last?.screen else { return .none }
      state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
      return .none

    case .routeAction(_, action: .detail(.delegate(.deleted))):
      return .send(.view(.backToRootAction))

    default:
      return .none
    }
  }

  func returnToClassDetail(
    state: inout State,
    action: ClassDetailFeature.View
  ) -> Effect<Action> {
    guard case let .ownerDashboard(dashboard)? = state.routes.last?.screen,
          let detailIndex = state.routes.lastIndex(where: {
            if case let .detail(detail) = $0.screen {
              return detail.room.id == dashboard.room.id
            }
            return false
          })
    else { return .none }

    for _ in (detailIndex + 1) ..< state.routes.count {
      state.routes.goBack()
    }
    return .send(.router(.routeAction(id: detailIndex, action: .detail(.view(action)))))
  }

  func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backAction:
      state.routes.goBack()
      return .none

    case .backToRootAction:
      state.routes.goBackToRoot()
      return .none
    }
  }

  func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .mockBattleRegistered(roomID, battleID):
      guard case let .detail(detail)? = state.routes.last?.screen,
            detail.room.id == roomID
      else { return .none }
      if detail.room.battle.id < 0 {
        state.routes.push(.aiVote(.init(room: detail.room, battleID: battleID)))
      } else {
        state.routes.push(.chat(.init(route: .preVote(battleId: battleID))))
      }
      return .none

    case let .membersLoaded(room, members, currentMemberID):
      guard let index = state.routes.lastIndex(where: {
        if case let .members(memberState) = $0.screen {
          return memberState.room.id == room.id
        }
        return false
      }) else { return .none }
      return .send(.router(.routeAction(
        id: index,
        action: .members(.membersLoaded(room: room, members: members, currentMemberID: currentMemberID))
      )))

    case let .membersFailed(roomID, message), let .memberMutationFailed(roomID, message):
      guard let index = state.routes.lastIndex(where: {
        if case let .members(memberState) = $0.screen {
          return memberState.room.id == roomID
        }
        return false
      }) else { return .none }
      return .send(.router(.routeAction(id: index, action: .members(.dataFailed(message)))))

    case let .memberMutationCompleted(room, members):
      var updates: [Effect<Action>] = []
      for (index, route) in state.routes.enumerated() {
        switch route.screen {
        case let .members(memberState) where memberState.room.id == room.id:
          updates.append(.send(.router(.routeAction(
            id: index,
            action: .members(.dataUpdated(room: room, members: members))
          ))))
        case let .detail(detailState) where detailState.room.id == room.id:
          updates.append(.send(.router(.routeAction(id: index, action: .detail(.dataUpdated(room))))))
        case .myClasses:
          updates.append(.send(.router(.routeAction(id: index, action: .myClasses(.view(.onAppear))))))
        default:
          break
        }
      }
      return .merge(updates)
    }
  }
}

// swiftformat:disable extensionAccessControl
extension ClassCoordinator {
  @Reducer
  public enum ClassScreen {
    case intro(ClassIntroFeature)
    case startMethod(ClassStartMethodFeature)
    case topic(ClassTopicFeature)
    case recommend(ClassRecommendFeature)
    case setting(ClassSettingFeature)
    case share(ClassShareFeature)
    case join(ClassJoinFeature)
    case myClasses(MyClassFeature)
    case detail(ClassDetailFeature)
    case members(ClassMemberFeature)
    case report(ClassReportFeature)
    case closedBattle(ClassClosedBattleFeature)
    case ownerDashboard(ClassOwnerDashboardFeature)
    case ownerMemberDetail(ClassMemberDetailFeature)
    case ownerReplyDetail(ClassReplyDetailFeature)
    case ownerFeedback(ClassFeedbackComposeFeature)
    case aiVote(ClassAIVoteFeature)
    case chat(ChatCoordinator)

    public static var body: some ReducerOf<Self> {
      @Dependency(\.classMockChatSession) var classMockChatSession
      @Dependency(\.classMockAudioPlayer) var classMockAudioPlayer
      Reduce { _, _ in .none }
        .ifCaseLet(\.intro, action: \.intro) { ClassIntroFeature() }
        .ifCaseLet(\.startMethod, action: \.startMethod) { ClassStartMethodFeature() }
        .ifCaseLet(\.topic, action: \.topic) { ClassTopicFeature() }
        .ifCaseLet(\.recommend, action: \.recommend) { ClassRecommendFeature() }
        .ifCaseLet(\.setting, action: \.setting) { ClassSettingFeature() }
        .ifCaseLet(\.share, action: \.share) { ClassShareFeature() }
        .ifCaseLet(\.join, action: \.join) { ClassJoinFeature() }
        .ifCaseLet(\.myClasses, action: \.myClasses) { MyClassFeature() }
        .ifCaseLet(\.detail, action: \.detail) { ClassDetailFeature() }
        .ifCaseLet(\.members, action: \.members) { ClassMemberFeature() }
        .ifCaseLet(\.report, action: \.report) { ClassReportFeature() }
        .ifCaseLet(\.closedBattle, action: \.closedBattle) { ClassClosedBattleFeature() }
        .ifCaseLet(\.ownerDashboard, action: \.ownerDashboard) { ClassOwnerDashboardFeature() }
        .ifCaseLet(\.ownerMemberDetail, action: \.ownerMemberDetail) { ClassMemberDetailFeature() }
        .ifCaseLet(\.ownerReplyDetail, action: \.ownerReplyDetail) { ClassReplyDetailFeature() }
        .ifCaseLet(\.ownerFeedback, action: \.ownerFeedback) { ClassFeedbackComposeFeature() }
        .ifCaseLet(\.aiVote, action: \.aiVote) {
          ClassAIVoteFeature()
            .dependency(\.battleUseCase, classMockChatSession)
        }
        .ifCaseLet(\.chat, action: \.chat) {
          ChatCoordinator()
            .dependency(\.battleUseCase, classMockChatSession)
            .dependency(\.perspectiveUseCase, classMockChatSession)
            .dependency(\.commentUseCase, classMockChatSession)
            .dependency(\.audioPlayer, classMockAudioPlayer)
            .dependency(\.analyticsUseCase, .testValue)
            .dependency(\.shareUseCase, .testValue)
        }
    }
  }
}

// swiftformat:enable extensionAccessControl

extension ClassCoordinator.ClassScreen.State: Equatable {}
