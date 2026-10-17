//
//  MainTabAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeAnalyticsInterface
import PickeDesignKit
import SwiftUI
import TCAFlow

/// Opt-in full-shell fixture for exercising the production tab router.
struct MainTabAuditView: View {
  @Bindable private var store: StoreOf<MainTabCoordinator>
  private let scenario: String
  @State private var mounted = false
  @FocusState private var fixtureFocused: Bool

  init(scenario: String) {
    self.scenario = scenario
    let source = scenario == "report" ? ClassRoom.mockClosedSociety : ClassRoom.mocks[0]
    let members = MockClassRepository.figmaOwnerMembers + (11 ... 22).map {
      ClassMember(id: $0, name: "검증 멤버 \($0)")
    }
    let room = ClassRoom(
      id: source.id,
      name: source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: source.deadline,
      memberCount: members.count,
      role: source.role,
      status: source.status,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: source.ownerParticipates,
      memberCapacity: 30
    )
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      reports: scenario == "report" ? [room.id: MockClassReport.figma] : nil,
      members: [room.id: members]
    )
    var state = MainTabCoordinator.State(
      selectedTab: scenario != "keyboard-mount"
        ? MainTabCoordinator.Tab.classroom.rawValue
        : MainTabCoordinator.Tab.home.rawValue
    )
    if case var .home(home) = state.homeState.routes[0].screen {
      home.hasLoadedHome = true
      home.hasTriedAttendance = true
      home.viewState = .loaded
      state.homeState.routes[screenAt: 0] = .home(home)
    }
    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    state.classState.routes.push(.myClasses(list))
    state.classState.routes.push(.detail(.init(room: room)))
    if scenario == "report" {
      // The participant comment flow replaces its route with a report above detail.
      let fixture = MockClassReport.figma
      var report = ClassReportFeature.State(room: room)
      report.report = fixture
      report.sourceViewState = .ready
      report.feedback = ClassAIPersonalFeedback(
        summaryTitle: fixture[.aiSummaryTitle],
        summaryDetail: fixture[.aiSummaryDetail],
        points: [
          .init(title: fixture[.feedbackTitle1], detail: fixture[.feedbackDetail1]),
          .init(title: fixture[.feedbackTitle2], detail: fixture[.feedbackDetail2]),
          .init(title: fixture[.feedbackTitle3], detail: fixture[.feedbackDetail3]),
        ],
        nextQuestion: fixture[.nextQuestion],
        nextHint: fixture[.nextHint]
      )
      state.classState.routes.push(.report(report))
    } else {
      state.classState.routes.push(.members(.init(
        room: room,
        members: members,
        currentMemberID: 1,
        instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        preloadedViewState: .loaded
      )))
    }
    store = withDependencies {
      $0.context = .test
      $0.feedAdUseCase = FeedAdUseCaseDependency.testValue
      $0.analyticsUseCase = .testValue
      $0.uuid = .incrementing
    } operation: {
      Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, ClassMockChatSession())
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }
    }
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      if scenario == "keyboard-mount" {
        keyboardFixture()
      }
      if scenario != "keyboard-mount" || mounted {
        MainTabView(store: store)
      }
      if scenario == "keyboard-mount", mounted {
        dismissKeyboardButton
      }
      diagnostics
    }
  }
}

private extension MainTabAuditView {
  @ViewBuilder
  func keyboardFixture() -> some View {
    VStack(spacing: 12) {
      TextField("키보드 검증", text: .constant(""))
        .focused($fixtureFocused)
        .accessibilityIdentifier("audit-keyboard-field")
      Button("탭 셸 장착") { mounted = true }
        .accessibilityIdentifier("audit-mount-tabs")
    }
    .padding(24)
    .frame(maxHeight: .infinity, alignment: .top)
  }

  var dismissKeyboardButton: some View {
    Button("키보드 닫기") { fixtureFocused = false }
      .accessibilityIdentifier("audit-dismiss-keyboard")
      .padding(.top, 40)
  }

  var diagnostics: some View {
    Text("Main tab audit")
      .pretendardFont(family: .Regular, size: 10)
      .accessibilityIdentifier("audit-main-tab-state")
      .accessibilityValue(diagnosticValue)
      .allowsHitTesting(false)
  }

  var diagnosticValue: String {
    let members: ClassMemberFeature.State? = {
      guard case let .members(value)? = store.classState.routes.last?.screen else { return nil }
      return value
    }()
    let report: ClassReportFeature.State? = {
      guard case let .report(value)? = store.classState.routes.last?.screen else { return nil }
      return value
    }()
    let values: [String: Any] = [
      "scenario": scenario,
      "mounted": scenario != "keyboard-mount" || mounted,
      "fixtureFocused": fixtureFocused,
      "selectedTab": store.selectedTab,
      "previousTab": store.previousTab,
      "shouldHideTabBar": store.shouldHideTabBar,
      "isKeyboardVisible": store.isKeyboardVisible,
      "classRouteCount": store.classState.routes.count,
      "classRouteKind": classRouteKind,
      "memberInstanceID": members?.instanceID.uuidString ?? "",
      "memberCount": members?.members.count ?? -1,
      "memberSearch": members?.searchText ?? "",
      "reportInstanceID": report?.instanceID.uuidString ?? "",
      "reportShowsMyOpinions": report?.showsMyOpinions ?? false,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else { return "{}" }
    return json
  }

  var classRouteKind: String {
    switch store.classState.routes.last?.screen {
    case .intro?: return "intro"
    case .myClasses?: return "list"
    case .detail?: return "detail"
    case .members?: return "members"
    case .report?: return "report"
    default: return "other"
    }
  }
}
