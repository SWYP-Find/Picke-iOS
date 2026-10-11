//
//  ClassCoordinator.swift
//  Picke
//
//  Created by Picke on 10/11/26.
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
    public var completedAIBattles: [Int: Bool] = [:]
    public var chatRoomsByBattleID: [Int: ClassRoom] = [:]
    var pendingJoinID: UUID?
    var reportInstanceIDs: Set<UUID> = []
    var dashboardInstanceIDs: Set<UUID> = []

    public init() {
      routes = [.root(.intro(.init()), embedInNavigationView: true)]
    }

    /// 클래스 목록과 상세에서만 모달이 닫힌 동안 탭바를 보여준다.
    public var showsTabBar: Bool {
      switch routes.last?.screen {
      case let .detail(detail)?:
        return detail.modal == nil && detail.customAlert == nil
      case let .myClasses(myClasses)?:
        return myClasses.modal == nil && myClasses.customAlert == nil && !myClasses.isLeaving
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
    case chatReportTapped(battleID: Int)
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {
    case membersLoaded(ClassRoom, [ClassMember], Int)
    case membersFailed(Int, String)
    case memberMutationCompleted(ClassRoom, [ClassMember])
    case memberMutationFailed(Int, String)
    case mockBattleRegistered(roomID: Int, battleID: Int)
    case completedAIVoteResolved(battleID: Int, isMindChanged: Bool)
    case membershipSessionCleared(routeID: Int, roomID: Int)
    case joinedSessionCleared(UUID, ClassRoom)
  }

  public enum NavigationAction: Equatable {}

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    let effect: Effect<Action> = switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)
    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)
    case let .inner(innerAction):
      handleInnerAction(state: &state, action: innerAction)
    case .async, .navigation:
      .none
    }
    if state.routes.count == 1 {
      state.chatRoomsByBattleID.removeAll()
    }
    return .merge(effect, cancelRemovedReportLoads(state: &state))
  }
}

private extension ClassCoordinator {
  func cancelRemovedReportLoads(state: inout State) -> Effect<Action> {
    let reportIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .report(report) = route.screen else { return nil }
      return report.instanceID
    })
    let dashboardIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .ownerDashboard(dashboard) = route.screen else { return nil }
      return dashboard.instanceID
    })
    // TCAFlow applies interactive route updates before handleRoute is called.
    // Keep instance IDs across actions so a removed route's work can be cancelled.
    let cancelledReports = state.reportInstanceIDs.subtracting(reportIDs)
    let cancelledDashboards = state.dashboardInstanceIDs.subtracting(dashboardIDs)
    state.reportInstanceIDs = reportIDs
    state.dashboardInstanceIDs = dashboardIDs
    return .merge(
      cancelledReports.map { .cancel(id: ClassReportFeature.CancelID.load($0)) }
        + cancelledDashboards.map { .cancel(id: ClassOwnerDashboardFeature.CancelID.load($0)) }
    )
  }

  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ClassScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .intro(.delegate(.joined(room, nickname: _)))):
      let requestID = UUID()
      state.pendingJoinID = requestID
      state.completedAIBattles[-1_000_000 - room.id] = nil
      state.chatRoomsByBattleID[-1_000_000 - room.id] = nil
      return .run { [classMockChatSession] send in
        await classMockChatSession.clear(roomID: room.id)
        await send(.inner(.joinedSessionCleared(requestID, room)))
      }

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
      state.chatRoomsByBattleID.removeAll()
      state.routes.push(.detail(.init(room: room)))
      return .none

    case .routeAction(_, action: .myClasses(.delegate(.dismiss))),
         .routeAction(_, action: .detail(.delegate(.dismiss))),
         .routeAction(_, action: .members(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .myClasses(.delegate(.openRoom(room)))):
      state.routes.push(.detail(.init(room: room)))
      return .none

    case let .routeAction(routeID, action: .myClasses(.delegate(.left(roomID)))):
      state.completedAIBattles[-1_000_000 - roomID] = nil
      state.chatRoomsByBattleID[-1_000_000 - roomID] = nil
      return .run { [classMockChatSession] send in
        await classMockChatSession.clear(roomID: roomID)
        await send(.inner(.membershipSessionCleared(routeID: routeID, roomID: roomID)))
      }

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
        state.routes.push(.ownerDashboard(.init(room: room)))
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

    case let .routeAction(_, action: .chat(.router(.routeAction(_, action: .preVote(.delegate(.voteSubmitted(
      battleID, .post, _, isMindChanged
    ))))))):
      guard case .aiChat? = state.routes.dropLast().last?.screen else { return .none }
      state.completedAIBattles[battleID] = isMindChanged
      return .none

    case .routeAction(_, action: .chat(.router(.routeAction(_, action: .comment(.delegate(.dismiss)))))):
      guard case .aiChat? = state.routes.dropLast().last?.screen else { return .none }
      state.routes.goBack()
      return .none

    case .routeAction(_, action: .aiVote(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .aiVote(.delegate(.voteSubmitted(
      battleID: battleID,
      selectedOptionID: selectedOptionID,
      hasCompletedPostVote: hasCompletedPostVote
    )))):
      guard case let .aiVote(vote)? = state.routes.last?.screen else { return .none }
      if hasCompletedPostVote {
        return .run { [classMockChatSession] send in
          let isMindChanged = await classMockChatSession.hasChangedMind(battleID: battleID)
          await send(.inner(.completedAIVoteResolved(
            battleID: battleID,
            isMindChanged: isMindChanged
          )))
        }
      }
      state.routes.push(.aiChat(.init(
        room: vote.room,
        battleID: battleID,
        selectedOptionID: selectedOptionID
      )))
      return .none

    case .routeAction(_, action: .aiChat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .aiChat(.delegate(.finalVote(battleID: battleID)))):
      guard case .aiChat? = state.routes.last?.screen else { return .none }
      if let isMindChanged = state.completedAIBattles[battleID] {
        var chat = ChatCoordinator.State(route: .comment(battleId: battleID))
        chat.routes[screenAt: 0] = .comment(.init(battleId: battleID, isMindChanged: isMindChanged))
        state.routes.push(.chat(chat))
      } else {
        state.routes.push(.chat(.init(route: .finalVote(battleId: battleID))))
      }
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
      state.chatRoomsByBattleID.removeAll()
      return .none

    case let .chatReportTapped(battleID):
      guard case let .chat(chat)? = state.routes.last?.screen,
            case let .comment(comment)? = chat.routes.last?.screen,
            comment.battleId == battleID,
            let room = state.chatRoomsByBattleID[battleID],
            let detailIndex = state.routes.dropLast().lastIndex(where: {
              if case let .detail(detail) = $0.screen {
                return detail.room.id == room.id
              }
              return false
            })
      else { return .none }

      while state.routes.count > detailIndex + 2 {
        state.routes.goBack()
      }
      state.routes[screenAt: detailIndex + 1] = room.role == .owner
        ? .ownerDashboard(.init(room: room))
        : .report(.init(room: room))
      return .none
    }
  }

  func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .joinedSessionCleared(requestID, room):
      guard state.pendingJoinID == requestID else { return .none }
      state.pendingJoinID = nil
      guard case .intro? = state.routes.last?.screen else { return .none }
      state.routes.push(.detail(.init(room: room)))
      return .none

    case let .membershipSessionCleared(routeID, roomID):
      guard state.routes.indices.contains(routeID),
            case let .myClasses(list) = state.routes[routeID].screen,
            list.isLeaving, list.leavingRoomID == roomID
      else { return .none }
      return .send(.router(.routeAction(
        id: routeID,
        action: .myClasses(.inner(.leaveCleanupCompleted(roomID)))
      )))

    case let .completedAIVoteResolved(battleID, isMindChanged):
      guard case let .aiVote(vote)? = state.routes.last?.screen,
            vote.battleID == battleID
      else { return .none }
      state.completedAIBattles[battleID] = isMindChanged
      var chat = ChatCoordinator.State(route: .comment(battleId: battleID))
      chat.routes[screenAt: 0] = .comment(.init(battleId: battleID, isMindChanged: isMindChanged))
      state.routes.push(.chat(chat))
      return .none

    case let .mockBattleRegistered(roomID, battleID):
      guard case let .detail(detail)? = state.routes.last?.screen,
            detail.room.id == roomID
      else { return .none }
      state.chatRoomsByBattleID[battleID] = detail.room
      // Keep this detail beneath both direct and AI chat routes so report can return here.
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
      for (battleID, context) in state.chatRoomsByBattleID where context.id == room.id {
        state.chatRoomsByBattleID[battleID] = room
      }
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
    case aiChat(ClassAIChatFeature)
    case chat(ChatCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension ClassCoordinator.ClassScreen.State: Equatable {}
