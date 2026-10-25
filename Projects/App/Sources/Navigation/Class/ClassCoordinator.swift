//
//  ClassCoordinator.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeCoreUtility
import TCAFlow

@FlowCoordinator(screen: "ClassScreen", navigation: true)
public struct ClassCoordinator {
  @Dependency(\.classMemberUseCase) private var classMemberUseCase
  @Dependency(\.classUseCase) private var classUseCase
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<ClassScreen.State>]
    public var usesAIQuestions = false
    public var completedAIBattles: [Int: Bool] = [:]
    public var chatRoomsByBattleID: [Int: ClassRoom] = [:]
    @Presents public var deadlineEdit: ClassDeadlineEditFeature.State?
    @Presents public var deadlineSelection: ClassDeadlineSelectionFeature.State?

    public var isDeadlinePanelPresented: Bool { deadlineEdit != nil || deadlineSelection != nil }
    var pendingJoinID: UUID?
    var completingJoinCodeInstanceID: UUID?
    var completingJoinNicknameInstanceID: UUID?
    var reportInstanceIDs: Set<UUID> = []
    var dashboardInstanceIDs: Set<UUID> = []
    var chatRoomInstanceIDs: Set<UUID> = []
    var ownerNameInstanceIDs: Set<UUID> = []
    var participantJoinInstanceIDs: Set<UUID> = []
    var memberInstanceIDs: Set<UUID> = []
    var detailInstanceIDs: Set<UUID> = []
    var aiVoteInstanceIDs: Set<UUID> = []
    var ticketInstanceIDs: Set<UUID> = []

    public init() {
      routes = [.root(.intro(.init()), embedInNavigationView: true)]
    }

    /// 클래스 목록·상세·리포트·의견·운영자 화면에서 모달이 닫힌 동안 탭바를 보여준다.
    public var showsTabBar: Bool {
      guard !isDeadlinePanelPresented else { return false }
      switch routes.last?.screen {
      case let .detail(detail)?:
        return detail.modal == nil && detail.customAlert == nil
      case let .myClasses(myClasses)?:
        return myClasses.modal == nil && myClasses.customAlert == nil && !myClasses.isLeaving
      case let .members(members)?:
        return members.filter == nil && members.editName == nil
          && members.customAlert == nil && !members.isSaving
      case let .ownerDashboard(dashboard)?:
        return dashboard.management == nil
      case .report?, .myOpinions?, .ticket?:
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
    case deadlineEdit(PresentationAction<ClassDeadlineEditFeature.Action>)
    case deadlineSelection(PresentationAction<ClassDeadlineSelectionFeature.Action>)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
    case chatReportTapped(battleID: Int)
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {
    case deadlineDetailResponse(routeID: Int, roomID: Int, Result<ClassRoom, ClassError>)
    case detailLoaded(routeID: Int, roomID: Int, instanceID: UUID, requestID: UUID, room: ClassRoom)
    case detailFailed(routeID: Int, roomID: Int, instanceID: UUID, requestID: UUID, message: String)
    case ticketRegistrationCompleted(routeID: Int, instanceID: UUID, startDate: Date, endDate: Date)
    case membersLoaded(
      routeID: Int,
      roomID: Int,
      instanceID: UUID,
      requestID: UUID,
      room: ClassRoom,
      members: [ClassMember],
      currentMemberID: Int
    )
    case membersFailed(
      routeID: Int,
      roomID: Int,
      instanceID: UUID,
      requestID: UUID,
      message: String
    )
    case memberMutationCompleted(ClassRoom, [ClassMember])
    case memberMutationFailed(Int, String)
    case membershipLeaveReady(routeID: Int, roomID: Int)
    case joinedNavigationReady(UUID, ClassRoom)
  }

  public enum NavigationAction: Equatable {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      if case .deadlineEdit(.dismiss) = action, state.deadlineEdit?.isSaving == true {
        return .none
      }
      if state.pendingJoinID != nil,
         isCompletingJoinPrefix(state),
         case let .router(.routeAction(routeID, action: .join(joinAction))) = action,
         routeID == state.routes.count - 1,
         case let .join(code)? = state.routes.last?.screen,
         code.mode == .code,
         code.instanceID == state.completingJoinCodeInstanceID
      {
        switch joinAction {
        case .view(.findTapped), .async(.find(_)):
          return .none
        default:
          break
        }
      }
      let effect = routedBody.reduce(into: &state, action: action)
      if let selection = state.deadlineSelection {
        if case let .setting(setting)? = state.routes.last?.screen,
           setting.instanceID == selection.settingInstanceID, setting.canEditDeadline {
          return effect
        }
        state.deadlineSelection = nil
      }
      return effect
    }
  }

  private var routedBody: some Reducer<State, Action> {
    Reduce { state, action in
      handleRoute(state: &state, action: action)
    }
    .forEachRoute(\.routes, action: \.router)
    .ifLet(\.$deadlineEdit, action: \.deadlineEdit) {
      ClassDeadlineEditFeature()
    }
    .ifLet(\.$deadlineSelection, action: \.deadlineSelection) {
      ClassDeadlineSelectionFeature()
    }
  }

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
    case let .deadlineEdit(deadlineAction):
      handleDeadlineEditAction(state: &state, action: deadlineAction)
    case let .deadlineSelection(selectionAction):
      handleDeadlineSelectionAction(state: &state, action: selectionAction)
    case .async, .navigation:
      .none
    }
    if state.pendingJoinID != nil, !isCompletingJoinPrefix(state) {
      invalidateCompletingJoin(state: &state)
    }
    if state.routes.count == 1 {
      state.chatRoomsByBattleID.removeAll()
    }
    return .merge(
      effect,
      cancelRemovedReportLoads(state: &state),
      cancelRemovedChatObservers(state: &state),
      cancelRemovedClassEffects(state: &state)
    )
  }
}

private extension ClassCoordinator {
  enum DetailLoadCancelID: Hashable {
    case load(UUID)
  }

  func fetchDetail(state: inout State, routeID: Int) -> Effect<Action> {
    guard state.routes.indices.contains(routeID),
          case var .detail(detail) = state.routes[routeID].screen
    else { return .none }
    let requestID = uuid()
    let roomID = detail.room.id
    let instanceID = detail.instanceID
    detail.viewState = .loading
    detail.loadErrorMessage = nil
    detail.activeLoadRequestID = requestID
    state.routes[screenAt: routeID] = .detail(detail)
    return .run { [classUseCase] send in
      do {
        let room = try await classUseCase.fetchClass(id: roomID)
        await send(.inner(.detailLoaded(
          routeID: routeID,
          roomID: roomID,
          instanceID: instanceID,
          requestID: requestID,
          room: room
        )))
      } catch {
        await send(.inner(.detailFailed(
          routeID: routeID,
          roomID: roomID,
          instanceID: instanceID,
          requestID: requestID,
          message: error.localizedDescription
        )))
      }
    }
    .cancellable(id: DetailLoadCancelID.load(instanceID), cancelInFlight: true)
  }

  func handleDeadlineSelectionAction(
    state: inout State,
    action: PresentationAction<ClassDeadlineSelectionFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .presented(.delegate(.dismiss)):
      state.deadlineSelection = nil
    case let .presented(.delegate(.confirmed(deadline, settingInstanceID: instanceID))):
      guard state.deadlineSelection?.settingInstanceID == instanceID,
            case var .setting(setting)? = state.routes.last?.screen,
            setting.instanceID == instanceID, setting.canEditDeadline
      else { return .none }
      let now = date.now
      guard deadline >= now else {
        state.deadlineSelection?.minimumDate = now
        return .none
      }
      setting.deadline = deadline
      setting.deadlineValidationMessage = nil
      state.routes[screenAt: state.routes.count - 1] = .setting(setting)
      state.deadlineSelection = nil
    case .presented:
      break
    }
    return .none
  }

  func openDeadlineEditor(
    state: inout State,
    room: ClassRoom
  ) -> Effect<Action> {
    guard room.role == .owner, state.deadlineEdit?.isSaving != true else { return .none }
    let previousID = state.deadlineEdit?.instanceID
    state.deadlineEdit = .init(room: room, instanceID: uuid(), referenceNow: date.now)
    return previousID.map { .cancel(id: ClassDeadlineEditFeature.CancelID.save($0)) } ?? .none
  }

  func handleDeadlineEditAction(
    state: inout State,
    action: PresentationAction<ClassDeadlineEditFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .presented(.delegate(.dismiss)):
      guard let editor = state.deadlineEdit, !editor.isSaving else { return .none }
      state.deadlineEdit = nil
      return .cancel(id: ClassDeadlineEditFeature.CancelID.save(editor.instanceID))

    case let .presented(.delegate(.saved(room, instanceID: instanceID, requestID: requestID))):
      guard let editor = state.deadlineEdit,
            editor.instanceID == instanceID,
            editor.activeRequestID == requestID,
            editor.room.id == room.id,
            editor.isSaving
      else { return .none }
      for (index, route) in state.routes.enumerated() {
        switch route.screen {
        case var .myClasses(list):
          for roomIndex in list.rooms.indices where list.rooms[roomIndex].id == room.id {
            list.rooms[roomIndex] = room
          }
          if list.viewState == .loaded || list.viewState == .empty {
            list.viewState = list.visibleRooms.isEmpty ? .empty : .loaded
          }
          state.routes[screenAt: index] = .myClasses(list)
        case var .detail(detail) where detail.room.id == room.id:
          detail.room = room
          state.routes[screenAt: index] = .detail(detail)
        case var .ownerDashboard(dashboard) where dashboard.room.id == room.id:
          dashboard.room = room
          state.routes[screenAt: index] = .ownerDashboard(dashboard)
        case var .closedBattle(closed) where closed.room.id == room.id:
          closed.room = room
          state.routes[screenAt: index] = .closedBattle(closed)
        case var .members(member) where member.room.id == room.id:
          member.room = room
          state.routes[screenAt: index] = .members(member)
        case var .report(report) where report.room.id == room.id:
          report.room = room
          state.routes[screenAt: index] = .report(report)
        default:
          break
        }
      }
      for (battleID, cachedRoom) in state.chatRoomsByBattleID where cachedRoom.id == room.id {
        state.chatRoomsByBattleID[battleID] = room
      }
      state.deadlineEdit = nil
      return .none

    case .presented:
      return .none
    }
  }

  func invalidateCompletingJoin(state: inout State) {
    state.pendingJoinID = nil
    state.completingJoinCodeInstanceID = nil
    state.completingJoinNicknameInstanceID = nil
  }

  func isCompletingJoinPrefix(_ state: State) -> Bool {
    guard state.pendingJoinID != nil,
          let codeID = state.completingJoinCodeInstanceID,
          let nicknameID = state.completingJoinNicknameInstanceID,
          (1 ... 3).contains(state.routes.count),
          case .intro = state.routes[0].screen
    else { return false }
    if state.routes.count >= 2 {
      guard case let .join(code) = state.routes[1].screen,
            code.mode == .code, code.instanceID == codeID
      else { return false }
    }
    if state.routes.count == 3 {
      guard case let .join(nickname) = state.routes[2].screen,
            nickname.mode == .nickname, nickname.instanceID == nicknameID
      else { return false }
    }
    return true
  }

  func fetchMembers(
    room: ClassRoom,
    routeID: Int,
    roomID: Int,
    instanceID: UUID,
    requestID: UUID
  ) -> Effect<Action> {
    let started: Effect<Action> = .send(.router(.routeAction(
      id: routeID,
      action: .members(.loadingStarted(requestID))
    )))
    let fetch: Effect<Action> = .run { [classMemberUseCase] send in
      do {
        let memberList = try await classMemberUseCase.fetchMembers(classID: roomID)
        await send(.inner(.membersLoaded(
          routeID: routeID,
          roomID: roomID,
          instanceID: instanceID,
          requestID: requestID,
          room: room,
          members: memberList.members,
          currentMemberID: memberList.currentMemberID
        )))
      } catch {
        await send(.inner(.membersFailed(
          routeID: routeID,
          roomID: roomID,
          instanceID: instanceID,
          requestID: requestID,
          message: error.localizedDescription
        )))
      }
    }
    .cancellable(id: ClassMemberFeature.CancelID.load(instanceID), cancelInFlight: true)
    return .concatenate(started, fetch)
  }

  func cancelRemovedClassEffects(state: inout State) -> Effect<Action> {
    let joinIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .join(join) = route.screen else { return nil }
      return join.instanceID
    })
    let ownerIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .ownerName(owner) = route.screen else { return nil }
      return owner.instanceID
    })
    let memberIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .members(member) = route.screen else { return nil }
      return member.instanceID
    })
    let detailIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .detail(detail) = route.screen else { return nil }
      return detail.instanceID
    })
    let voteIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .aiVote(vote) = route.screen else { return nil }
      return vote.instanceID
    })
    let ticketIDs = Set(state.routes.compactMap { route -> UUID? in
      guard case let .ticket(ticket) = route.screen else { return nil }
      return ticket.instanceID
    })
    let removedOwners = state.ownerNameInstanceIDs.subtracting(ownerIDs)
    let removedJoins = state.participantJoinInstanceIDs.subtracting(joinIDs)
    let removedMembers = state.memberInstanceIDs.subtracting(memberIDs)
    let removedDetails = state.detailInstanceIDs.subtracting(detailIDs)
    let removedVotes = state.aiVoteInstanceIDs.subtracting(voteIDs)
    let removedTickets = state.ticketInstanceIDs.subtracting(ticketIDs)
    state.ownerNameInstanceIDs = ownerIDs
    state.participantJoinInstanceIDs = joinIDs
    state.memberInstanceIDs = memberIDs
    state.detailInstanceIDs = detailIDs
    state.aiVoteInstanceIDs = voteIDs
    state.ticketInstanceIDs = ticketIDs
    return .merge(
      removedOwners.map { .cancel(id: ClassJoinFeature.CancelID.nameOwner($0)) }
        + removedJoins.flatMap { id in
          [
            .cancel(id: ClassJoinFeature.CancelID.find(id)),
            .cancel(id: ClassJoinFeature.CancelID.join(id)),
          ]
        }
        + removedMembers.map { .cancel(id: ClassMemberFeature.CancelID.load($0)) }
        + removedDetails.map { .cancel(id: DetailLoadCancelID.load($0)) }
        + removedVotes.flatMap { id in
          [
            .cancel(id: ClassAIVoteFeature.CancelID.load(id)),
            .cancel(id: ClassAIVoteFeature.CancelID.submit(id)),
          ]
        }
        + removedTickets.map { .cancel(id: ClassTicketFeature.CancelID.check($0)) }
    )
  }

  func cancelRemovedChatObservers(state: inout State) -> Effect<Action> {
    let currentIDs = Set(state.routes.flatMap { route -> Set<UUID> in
      guard case let .chat(chat) = route.screen else { return [] }
      return chat.activeChatRoomInstanceIDs
    })
    let removedIDs = state.chatRoomInstanceIDs.subtracting(currentIDs)
    state.chatRoomInstanceIDs = currentIDs
    return .merge(removedIDs.map { .cancel(id: ChatRoomFeature.CancelID.audioObserver($0)) })
  }

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
      cancelledReports.flatMap { id in
        [
          .cancel(id: ClassReportFeature.CancelID.load(id)),
          .cancel(id: ClassReportFeature.CancelID.generate(id)),
        ]
      }
        + cancelledDashboards.flatMap { id in
          [
            .cancel(id: ClassOwnerDashboardFeature.CancelID.load(id)),
            .cancel(id: ClassOwnerDashboardFeature.CancelID.generate(id)),
            .cancel(id: ClassOwnerDashboardFeature.CancelID.generatePersonal(id)),
          ]
        }
    )
  }

  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ClassScreen>
  ) -> Effect<Action> {
    switch action {
    case .routeAction(_, action: .intro(.delegate(.backToHome))):
      invalidateCompletingJoin(state: &state)
      return .none

    case let .routeAction(routeID, action: .intro(.delegate(.join))):
      guard routeID == 0, state.routes.count == 1,
            case .intro = state.routes[0].screen
      else { return .none }
      invalidateCompletingJoin(state: &state)
      state.routes.push(.join(.init(mode: .code, instanceID: uuid())))
      return .none

    case let .routeAction(routeID, action: .intro(.delegate(.ticket))):
      guard routeID == 0, state.routes.count == 1,
            case .intro = state.routes[0].screen
      else { return .none }
      invalidateCompletingJoin(state: &state)
      state.routes.push(.ticket(.init(instanceID: uuid())))
      return .none

    case let .routeAction(routeID, action: .ticket(.delegate(.registrationConfirmed(startDate: startDate, endDate: endDate)))):
      guard routeID == state.routes.count - 1,
            case let .ticket(completed)? = state.routes.last?.screen,
            completed.phase == .registered,
            completed.registrationStartDate == startDate,
            completed.expirationDate == endDate
      else { return .none }
      return .send(.inner(.ticketRegistrationCompleted(
        routeID: routeID,
        instanceID: completed.instanceID,
        startDate: startDate,
        endDate: endDate
      )))

    case let .routeAction(routeID, action: .ticket(.delegate(.registered(startDate, endDate)))):
      guard routeID == state.routes.count - 1,
            routeID >= 2,
            case let .ticket(registered)? = state.routes.last?.screen,
            registered.phase == .registered,
            registered.registrationStartDate == startDate,
            registered.expirationDate == endDate,
            case var .ticket(overview) = state.routes[routeID - 1].screen,
            overview.phase == .overview
      else { return .none }
      overview.registrationStartDate = startDate
      overview.expirationDate = endDate
      overview.ticket = registered.ticket
      state.routes[screenAt: routeID - 1] = .ticket(overview)
      if routeID >= 3,
         case var .ticket(original) = state.routes[routeID - 2].screen,
         original.phase == .registered
      {
        original.registrationStartDate = startDate
        original.expirationDate = endDate
        original.ticket = registered.ticket
        state.routes[screenAt: routeID - 2] = .ticket(original)
      }
      return .none

    case let .routeAction(routeID, action: .ticket(.delegate(.addRegistrationRequested))):
      guard routeID == state.routes.count - 1,
            case let .ticket(overview)? = state.routes.last?.screen,
            overview.phase == .overview
      else { return .none }
      var registration = ClassTicketFeature.State(instanceID: uuid())
      registration.shouldCheckExistingTicket = false
      state.routes.push(.ticket(registration))
      return .none

    case let .routeAction(routeID, action: .ticket(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case .ticket = state.routes.last?.screen
      else { return .none }
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .join(.delegate(.found(room, instanceID: instanceID)))):
      guard routeID == state.routes.count - 1,
            let instanceID,
            case let .join(code)? = state.routes.last?.screen,
            code.mode == .code, code.instanceID == instanceID,
            case .intro? = state.routes.first?.screen
      else { return .none }
      invalidateCompletingJoin(state: &state)
      state.routes.push(.join(.init(mode: .nickname, preview: room, instanceID: uuid())))
      return .none

    case let .routeAction(routeID, action: .join(.delegate(.createClassRequested))):
      guard routeID == state.routes.count - 1,
            case let .join(join)? = state.routes.last?.screen,
            join.mode == .code,
            state.routes.count == 2,
            case .intro = state.routes[0].screen
      else { return .none }
      invalidateCompletingJoin(state: &state)
      state.routes.push(.startMethod(.init()))
      return .none

    case let .routeAction(routeID, action: .join(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case let .join(join)? = state.routes.last?.screen
      else { return .none }
      if state.pendingJoinID != nil,
         join.instanceID == state.completingJoinNicknameInstanceID
      {
        return .none
      }
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .join(.delegate(.joined(room, nickname: _, instanceID: instanceID)))):
      guard routeID == 2, state.routes.count == 3,
            let instanceID,
            case .intro = state.routes[0].screen,
            case let .join(code) = state.routes[1].screen,
            code.mode == .code, let codeID = code.instanceID,
            case let .join(nickname) = state.routes[2].screen,
            nickname.mode == .nickname,
            nickname.instanceID == instanceID,
            nickname.preview == nil,
            state.pendingJoinID == nil
      else { return .none }
      let requestID = uuid()
      state.pendingJoinID = requestID
      state.completingJoinCodeInstanceID = codeID
      state.completingJoinNicknameInstanceID = instanceID
      state.completedAIBattles[-1_000_000 - room.id] = nil
      state.chatRoomsByBattleID[-1_000_000 - room.id] = nil
      return .send(.inner(.joinedNavigationReady(requestID, room)))

    case let .routeAction(routeID, action: .join(.async(.find(_)))):
      if routeID == state.routes.count - 1,
         case let .join(code)? = state.routes.last?.screen,
         code.mode == .code, code.activeFindRequestID != nil
      {
        invalidateCompletingJoin(state: &state)
      }
      return .none

    case let .routeAction(routeID, action: .join(.async(.join(joinCode: _, nickname: _)))):
      if routeID == state.routes.count - 1,
         case let .join(nickname)? = state.routes.last?.screen,
         nickname.mode == .nickname, nickname.activeJoinRequestID != nil
      {
        invalidateCompletingJoin(state: &state)
      }
      return .none

    case .routeAction(_, action: .intro(.delegate(.myClasses))):
      invalidateCompletingJoin(state: &state)
      state.routes.push(.myClasses(.init()))
      return .none

    case .routeAction(_, action: .intro(.delegate(.create))):
      invalidateCompletingJoin(state: &state)
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
      state.routes.push(.setting(.init(battle: battle, instanceID: uuid())))
      return .none

    case let .routeAction(routeID, action: .recommend(.delegate(.previewRequested(battle)))):
      guard routeID == state.routes.count - 1,
            case .recommend? = state.routes.last?.screen
      else { return .none }
      state.routes.push(.battlePreview(.init(battle: battle)))
      return .none

    case .routeAction(_, action: .battlePreview(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .recommend(.delegate(.selectAIQuestion(version, filter)))):
      var setting = ClassSettingFeature.State()
      setting.aiQuestion = ClassAIQuestion(version: version)
      setting.topicVersionID = version.id
      setting.filter = filter
      setting.instanceID = uuid()
      state.routes.push(.setting(setting))
      return .none

    case let .routeAction(routeID, action: .setting(.delegate(.editDeadline(instanceID)))):
      guard routeID == state.routes.count - 1,
            state.deadlineEdit == nil,
            case let .setting(setting)? = state.routes.last?.screen,
            setting.instanceID == instanceID, setting.canEditDeadline
      else { return .none }
      var selection = ClassDeadlineSelectionFeature.State()
      selection.settingInstanceID = instanceID
      let now = date.now
      selection.minimumDate = now
      let nextMinute = AppDateFormat.calendar.dateInterval(of: .minute, for: now)?.end
        ?? now.addingTimeInterval(60)
      selection.draftDeadline = setting.deadline > now ? setting.deadline : nextMinute
      state.deadlineSelection = selection
      return .none

    case .routeAction(_, action: .setting(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .setting(.delegate(.created(room)))):
      state.routes.push(.share(.init(room: room)))
      return .none

    case .routeAction(_, action: .share(.delegate(.dismiss))):
      return .send(.view(.backToRootAction))

    case let .routeAction(routeID, action: .share(.delegate(.nameOwner(room)))):
      guard routeID == state.routes.count - 1,
            case let .share(share)? = state.routes.last?.screen,
            share.room.id == room.id
      else { return .none }
      state.routes.push(.ownerName(.init(
        mode: .ownerName,
        preview: room,
        instanceID: uuid()
      )))
      return .none

    case .routeAction(_, action: .ownerName(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .ownerName(.delegate(.ownerNamed(room, instanceID: instanceID)))):
      guard routeID == state.routes.count - 1,
            state.routes.count >= 2,
            case let .ownerName(owner)? = state.routes.last?.screen,
            owner.instanceID == instanceID,
            owner.mode == .ownerName,
            owner.preview == nil,
            case let .share(share) = state.routes[state.routes.count - 2].screen,
            share.room.id == room.id
      else { return .none }
      state.routes.goBackToRoot()
      state.chatRoomsByBattleID.removeAll()
      state.routes.push(.detail(.init(room: room)))
      return .none

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
      let detailRouteID = state.routes.count - 1
      return fetchDetail(state: &state, routeID: detailRouteID)

    case let .routeAction(routeID, action: .detail(.delegate(.retryRequested(roomID, instanceID)))):
      guard routeID == state.routes.count - 1,
            case let .detail(detail)? = state.routes.last?.screen,
            detail.room.id == roomID,
            detail.instanceID == instanceID,
            detail.viewState == .error
      else { return .none }
      return fetchDetail(state: &state, routeID: routeID)

    case let .routeAction(routeID, action: .myClasses(.delegate(.left(roomID)))):
      state.completedAIBattles[-1_000_000 - roomID] = nil
      state.chatRoomsByBattleID[-1_000_000 - roomID] = nil
      return .send(.inner(.membershipLeaveReady(routeID: routeID, roomID: roomID)))

    case let .routeAction(routeID, action: .myClasses(.delegate(.openInformation(room)))):
      guard routeID == state.routes.count - 1,
            case let .myClasses(list)? = state.routes.last?.screen,
            list.rooms.contains(where: { $0.id == room.id })
      else { return .none }
      return .run { [classUseCase] send in
        let result = await Result { try await classUseCase.fetchClass(id: room.id) }
          .mapError(ClassError.from)
        await send(.inner(.deadlineDetailResponse(routeID: routeID, roomID: room.id, result)))
      }

    case let .routeAction(routeID, action: .detail(.delegate(.openDeadline(room)))):
      guard routeID == state.routes.count - 1,
            case let .detail(detail)? = state.routes.last?.screen,
            detail.room.id == room.id
      else { return .none }
      return openDeadlineEditor(state: &state, room: room)

    case let .routeAction(_, action: .detail(.delegate(.openMembers(room)))):
      let member = ClassMemberFeature.State(room: room, instanceID: uuid())
      state.routes.push(.members(member))
      return fetchMembers(
        room: room,
        routeID: state.routes.count - 1,
        roomID: room.id,
        instanceID: member.instanceID,
        requestID: uuid()
      )

    case let .routeAction(routeID, action: .members(.delegate(.retryMembers(roomID)))):
      guard routeID == state.routes.count - 1,
            case let .members(member)? = state.routes.last?.screen,
            member.room.id == roomID
      else { return .none }
      return fetchMembers(
        room: member.room,
        routeID: routeID,
        roomID: roomID,
        instanceID: member.instanceID,
        requestID: uuid()
      )

    case let .routeAction(
      _,
      action: .members(.delegate(.removeMember(roomID: roomID, memberID: memberID, currentMemberID: currentMemberID)))
    ):
      guard memberID != currentMemberID else {
        return .send(.inner(.memberMutationFailed(roomID, "본인은 내보낼 수 없어요.")))
      }
      return .run { [classMemberUseCase, classUseCase] send in
        do {
          try await classMemberUseCase.removeMember(classID: roomID, memberID: memberID)
          let memberList = try await classMemberUseCase.fetchMembers(classID: roomID)
          let room = try await classUseCase.fetchClass(id: roomID)
          await send(.inner(.memberMutationCompleted(room, memberList.members)))
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
      guard memberID == currentMemberID else {
        return .send(.inner(.memberMutationFailed(roomID, "본인 이름만 바꿀 수 있어요.")))
      }
      return .run { [classMemberUseCase, classUseCase] send in
        do {
          _ = try await classMemberUseCase.updateMyDisplayName(classID: roomID, name: name)
          let memberList = try await classMemberUseCase.fetchMembers(classID: roomID)
          let room = try await classUseCase.fetchClass(id: roomID)
          await send(.inner(.memberMutationCompleted(room, memberList.members)))
        } catch {
          await send(.inner(.memberMutationFailed(roomID, error.localizedDescription)))
        }
      }

    case let .routeAction(_, action: .detail(.delegate(.openBattle(room)))):
      if room.battleType == .custom {
        state.routes.push(.aiVote(.init(
          room: room,
          battleID: room.battle.id,
          isLiveClassBattle: true
        )))
      } else {
        var battleFlowState = ClassBattleFlowFeature.State()
        battleFlowState.room = room
        state.routes.push(.battleFlow(battleFlowState))
      }
      return .none

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

    case let .routeAction(routeID, action: .report(.delegate(.openMyOpinions(instanceID)))):
      guard routeID == state.routes.count - 1,
            case let .report(report)? = state.routes.last?.screen,
            report.instanceID == instanceID,
            report.sourceViewState == .ready,
            let source = report.report
      else { return .none }
      var opinions = ClassMyOpinionsFeature.State()
      opinions.opinions = source.resolvedOpinions
      state.routes.push(.myOpinions(opinions))
      return .none

    case let .routeAction(routeID, action: .ownerDashboard(.delegate(.openMyOpinions(instanceID)))):
      guard routeID == state.routes.count - 1,
            case let .ownerDashboard(dashboard)? = state.routes.last?.screen,
            dashboard.instanceID == instanceID,
            dashboard.selectedTab == .report,
            dashboard.sourceViewState == .ready,
            dashboard.management == nil,
            let report = dashboard.report
      else { return .none }
      var opinions = ClassMyOpinionsFeature.State()
      opinions.opinions = report.resolvedOpinions
      state.routes.push(.myOpinions(opinions))
      return .none

    case let .routeAction(routeID, action: .report(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case .report? = state.routes.last?.screen
      else { return .none }
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .myOpinions(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case .myOpinions? = state.routes.last?.screen
      else { return .none }
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .ownerDashboard(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case .ownerDashboard? = state.routes.last?.screen
      else { return .none }
      return .send(.view(.backAction))

    case .routeAction(_, action: .ownerMemberDetail(.delegate(.dismiss))),
         .routeAction(_, action: .ownerReplyDetail(.delegate(.dismiss))),
         .routeAction(_, action: .ownerFeedback(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .ownerDashboard(.delegate(.editClass))):
      guard routeID == state.routes.count - 1,
            case let .ownerDashboard(dashboard)? = state.routes.last?.screen
      else { return .none }
      return openDeadlineEditor(state: &state, room: dashboard.room)

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

    case let .routeAction(routeID, action: .battleFlow(.delegate(.dismiss))):
      guard routeID == state.routes.count - 1,
            case .battleFlow? = state.routes.last?.screen else { return .none }
      return .send(.view(.backAction))

    case let .routeAction(routeID, action: .battleFlow(.delegate(.completed(classID: classID)))):
      guard routeID == state.routes.count - 1,
            case let .battleFlow(flow)? = state.routes.last?.screen,
            flow.room?.id == classID else { return .none }
      guard let detailIndex = state.routes.lastIndex(where: {
        guard case let .detail(detail) = $0.screen else { return false }
        return detail.room.id == classID
      }) else { return .none }
      for _ in (detailIndex + 1) ..< state.routes.count {
        state.routes.goBack()
      }
      return .none

    case let .routeAction(_, action: .aiVote(.delegate(.voteSubmitted(
      battleID: battleID,
      selectedOptionID: selectedOptionID,
      hasCompletedPostVote: hasCompletedPostVote
    )))):
      guard case let .aiVote(vote)? = state.routes.last?.screen else { return .none }
      if hasCompletedPostVote {
        if vote.room.requiresComment {
          var battleFlowState = ClassBattleFlowFeature.State()
          battleFlowState.room = vote.room
          state.routes.push(.battleFlow(battleFlowState))
          return .none
        }
        guard let detailIndex = state.routes.lastIndex(where: {
          guard case let .detail(detail) = $0.screen else { return false }
          return detail.room.id == vote.room.id
        }) else { return .none }
        for _ in (detailIndex + 1) ..< state.routes.count {
          state.routes.goBack()
        }
        return .none
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
      guard case let .aiChat(aiChat)? = state.routes.last?.screen else { return .none }
      state.routes.push(.aiVote(.init(
        room: aiChat.room,
        battleID: battleID,
        isLiveClassBattle: true,
        isPostVote: true
      )))
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
    let room: ClassRoom
    switch state.routes.last?.screen {
    case let .ownerDashboard(dashboard):
      room = dashboard.room
    default:
      return .none
    }
    guard let detailIndex = state.routes.lastIndex(where: {
      if case let .detail(detail) = $0.screen {
        return detail.room.id == room.id
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
      if state.deadlineSelection != nil {
        state.deadlineSelection = nil
        return .none
      }
      if let editor = state.deadlineEdit {
        guard !editor.isSaving else { return .none }
        state.deadlineEdit = nil
        return .cancel(id: ClassDeadlineEditFeature.CancelID.save(editor.instanceID))
      }
      if state.pendingJoinID != nil,
         state.routes.count == 3,
         case let .join(join)? = state.routes.last?.screen,
         join.instanceID == state.completingJoinNicknameInstanceID
      {
        return .none
      }
      state.routes.goBack()
      return .none

    case .backToRootAction:
      state.deadlineSelection = nil
      if let editor = state.deadlineEdit {
        guard !editor.isSaving else { return .none }
        state.deadlineEdit = nil
        invalidateCompletingJoin(state: &state)
        state.routes.goBackToRoot()
        state.chatRoomsByBattleID.removeAll()
        return .cancel(id: ClassDeadlineEditFeature.CancelID.save(editor.instanceID))
      }
      invalidateCompletingJoin(state: &state)
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
    case let .deadlineDetailResponse(routeID, roomID, result):
      guard routeID == state.routes.count - 1,
            case var .myClasses(list)? = state.routes.last?.screen,
            list.rooms.contains(where: { $0.id == roomID })
      else { return .none }
      switch result {
      case let .success(room):
        guard room.id == roomID else { return .none }
        return openDeadlineEditor(state: &state, room: room)
      case let .failure(error):
        list.customAlert = .alert(
          title: "클래스 정보를 불러오지 못했어요",
          message: error.localizedDescription
        )
        state.routes[screenAt: routeID] = .myClasses(list)
        return .none
      }

    case let .detailLoaded(routeID, roomID, instanceID, requestID, room):
      guard room.id == roomID,
            state.routes.indices.contains(routeID),
            case var .detail(detail) = state.routes[routeID].screen,
            detail.room.id == roomID,
            detail.instanceID == instanceID,
            detail.activeLoadRequestID == requestID
      else { return .none }
      detail.room = room
      detail.viewState = .loaded
      detail.loadErrorMessage = nil
      detail.activeLoadRequestID = nil
      state.routes[screenAt: routeID] = .detail(detail)
      return .none

    case let .detailFailed(routeID, roomID, instanceID, requestID, message):
      guard state.routes.indices.contains(routeID),
            case var .detail(detail) = state.routes[routeID].screen,
            detail.room.id == roomID,
            detail.instanceID == instanceID,
            detail.activeLoadRequestID == requestID
      else { return .none }
      detail.viewState = .error
      detail.loadErrorMessage = message
      detail.activeLoadRequestID = nil
      state.routes[screenAt: routeID] = .detail(detail)
      return .none

    case let .ticketRegistrationCompleted(routeID, instanceID, startDate, endDate):
      guard routeID == state.routes.count - 1,
            case let .ticket(completed)? = state.routes.last?.screen,
            completed.instanceID == instanceID,
            completed.phase == .registered,
            completed.registrationStartDate == startDate,
            completed.expirationDate == endDate
      else { return .none }

      if routeID >= 2,
         case let .ticket(previous) = state.routes[routeID - 1].screen,
         previous.phase == .overview
      {
        state.routes.goBack()
        var overview = previous
        overview.registrationStartDate = startDate
        overview.expirationDate = endDate
        overview.ticket = completed.ticket
        state.routes[screenAt: routeID - 1] = .ticket(overview)
        if routeID >= 3,
           case var .ticket(original) = state.routes[routeID - 2].screen,
           original.phase == .registered
        {
          original.registrationStartDate = startDate
          original.expirationDate = endDate
          original.ticket = completed.ticket
          state.routes[screenAt: routeID - 2] = .ticket(original)
        }
        return .none
      }

      var overview = ClassTicketFeature.State(instanceID: uuid())
      overview.phase = .overview
      overview.ticket = completed.ticket
      overview.registrationStartDate = startDate
      overview.expirationDate = endDate
      state.routes.push(.ticket(overview))
      return .none

    case let .joinedNavigationReady(requestID, room):
      guard state.pendingJoinID == requestID,
            isCompletingJoinPrefix(state)
      else { return .none }
      invalidateCompletingJoin(state: &state)
      state.routes.goBackToRoot()
      state.routes.push(.detail(.init(room: room)))
      return .none

    case let .membershipLeaveReady(routeID, roomID):
      guard state.routes.indices.contains(routeID),
            case let .myClasses(list) = state.routes[routeID].screen,
            list.isLeaving, list.leavingRoomID == roomID
      else { return .none }
      return .send(.router(.routeAction(
        id: routeID,
        action: .myClasses(.inner(.leaveCleanupCompleted(roomID)))
      )))

    case let .membersLoaded(routeID, roomID, instanceID, requestID, _, members, currentMemberID):
      guard state.routes.indices.contains(routeID),
            case let .members(member) = state.routes[routeID].screen,
            member.room.id == roomID,
            member.instanceID == instanceID,
            member.activeLoadRequestID == requestID
      else { return .none }
      return .send(.router(.routeAction(
        id: routeID,
        action: .members(.membersLoaded(
          room: member.room,
          members: members,
          currentMemberID: currentMemberID,
          requestID: requestID
        ))
      )))

    case let .membersFailed(routeID, roomID, instanceID, requestID, message):
      guard state.routes.indices.contains(routeID),
            case let .members(member) = state.routes[routeID].screen,
            member.room.id == roomID,
            member.instanceID == instanceID,
            member.activeLoadRequestID == requestID
      else { return .none }
      return .send(.router(.routeAction(
        id: routeID,
        action: .members(.loadFailed(requestID: requestID, message: message))
      )))

    case let .memberMutationFailed(roomID, message):
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
    case ticket(ClassTicketFeature)
    case join(ClassJoinFeature)
    case startMethod(ClassStartMethodFeature)
    case topic(ClassTopicFeature)
    case recommend(ClassRecommendFeature)
    case battlePreview(ClassBattlePreviewFeature)
    case setting(ClassSettingFeature)
    case share(ClassShareFeature)
    case ownerName(ClassJoinFeature)
    case myClasses(MyClassFeature)
    case detail(ClassDetailFeature)
    case members(ClassMemberFeature)
    case report(ClassReportFeature)
    case myOpinions(ClassMyOpinionsFeature)
    case closedBattle(ClassClosedBattleFeature)
    case ownerDashboard(ClassOwnerDashboardFeature)
    case ownerMemberDetail(ClassMemberDetailFeature)
    case ownerReplyDetail(ClassReplyDetailFeature)
    case ownerFeedback(ClassFeedbackComposeFeature)
    case aiVote(ClassAIVoteFeature)
    case aiChat(ClassAIChatFeature)
    case battleFlow(ClassBattleFlowFeature)
    case chat(ChatCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension ClassCoordinator.ClassScreen.State: Equatable {}
