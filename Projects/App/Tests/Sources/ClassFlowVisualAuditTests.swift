import AudioPlayerServiceInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import PickeAnalyticsInterface
import PickeCoreUtility
import SwiftUI
import TCAFlow
import UIKit
import XCTest

/// Run explicitly with PICKE_CLASS_VISUAL_AUDIT=1. These images are evidence for
/// manual Figma comparison, not snapshot assertions or proof of design parity.
final class ClassFlowVisualAuditTests: XCTestCase {
  @MainActor
  func testPresentClassTabForInteractiveAudit() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_INTERACTIVE_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_INTERACTIVE_AUDIT=1 for a manual Class tab session")
    }
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let repository = MockClassRepository()
    let session = ClassMockChatSession()
    let store = Store(initialState: MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)) {
      MainTabCoordinator()
        .dependency(\.classUseCase, repository)
        .dependency(\.classMockRepository, repository)
        .dependency(\.classMockChatSession, session)
        .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
    }
    window.rootViewController = UIHostingController(rootView: MainTabView(store: store))
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    try await Task.sleep(for: .seconds(180))
  }

  @MainActor
  func testCaptureClassFlowFrames() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture the Class user flow")
    }

    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassVisualAudit", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let frames = try await withDependencies {
      $0.context = .test
    } operation: {
      try await makeFrames()
    }
    var records: [Record] = []
    for frame in frames {
      guard let view = frame.view else {
        records.append(.init(
          number: frame.number,
          title: frame.title,
          status: "unavailable",
          detail: frame.detail,
          width: nil,
          height: nil
        ))
        continue
      }
      let (image, bottomImage, contentReady) = try await capture(
        view,
        ready: frame.ready,
        includeScrollBottom: [19, 23, 25].contains(frame.number)
      )
      let name = String(format: "%02d", frame.number) + "-" + frame.slug + ".png"
      try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name))
      let attachment = XCTAttachment(image: image)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
      if let bottomImage {
        let bottomName = String(format: "%02d", frame.number) + "-" + frame.slug + "-bottom.png"
        try XCTUnwrap(bottomImage.pngData()).write(to: directory.appendingPathComponent(bottomName))
        let bottomAttachment = XCTAttachment(image: bottomImage)
        bottomAttachment.name = bottomName
        bottomAttachment.lifetime = .keepAlways
        add(bottomAttachment)
      }
      records.append(.init(
        number: frame.number,
        title: frame.title,
        status: contentReady
          ? "captured; visual comparison pending"
          : "captured; async content did not finish loading",
        detail: frame.detail,
        width: image.cgImage?.width,
        height: image.cgImage?.height
      ))
    }

    let manifest = try JSONEncoder().encode(records)
    try manifest.write(to: directory.appendingPathComponent("manifest.json"))
    XCTAssertEqual(records.count, 28)
  }

  private struct Frame {
    let number: Int
    let title: String
    let slug: String
    let detail: String
    let view: AnyView?
    let ready: (@MainActor () -> Bool)?
  }

  private struct Record: Codable {
    let number: Int
    let title: String
    let status: String
    let detail: String
    let width: Int?
    let height: Int?
  }

  @MainActor
  private func capture(
    _ view: AnyView,
    ready: (@MainActor () -> Bool)?,
    includeScrollBottom: Bool
  ) async throws -> (UIImage, UIImage?, Bool) {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: view)
    window.rootViewController = host
    window.frame = scene.coordinateSpace.bounds
    window.makeKeyAndVisible()
    host.view.frame = window.bounds
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    await Task.yield()
    if let ready {
      for _ in 0 ..< 50 {
        if ready() {
          break
        }
        try await Task.sleep(for: .milliseconds(100))
      }
    }
    // Allow the first SwiftUI layout and the shared alert's 0.3s transition to settle.
    try await Task.sleep(for: .milliseconds(400))
    host.view.layoutIfNeeded()
    CATransaction.flush()

    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    let image = renderer.image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    var bottomImage: UIImage?
    if includeScrollBottom {
      let scrollView = try XCTUnwrap(verticalScrollViews(in: host.view).max {
        $0.bounds.height < $1.bounds.height
      }, "Expected report content to have a vertical scroll view")
      scrollView.setContentOffset(CGPoint(
        x: scrollView.contentOffset.x,
        y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
      ), animated: false)
      try await Task.sleep(for: .milliseconds(100))
      host.view.layoutIfNeeded()
      bottomImage = renderer.image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
    }
    window.isHidden = true
    return (image, bottomImage, ready?() ?? true)
  }

  @MainActor
  private func verticalScrollViews(in view: UIView) -> [UIScrollView] {
    let candidates = view.subviews.flatMap { verticalScrollViews(in: $0) }
    guard let scrollView = view as? UIScrollView,
          !scrollView.isHidden,
          scrollView.bounds.height > 0,
          scrollView.contentSize.height > scrollView.bounds.height + 1 else { return candidates }
    return [scrollView] + candidates
  }

  @MainActor
  private func makeFrames() async throws -> [Frame] {
    let owner = ClassRoom.mocks[0]
    let member = ClassRoom.mockJoinable
    let aiQuestion = ClassAIQuestion.examples[0]
    let filter = ClassTopicFilter(categories: [.philosophy])
    var topic = ClassTopicFeature.State()
    topic.categories = [.philosophy]
    let aiBattle = try XCTUnwrap(ClassSettingFeature.State(aiQuestion: aiQuestion, filter: filter).aiBattle)
    let aiRoom = ClassRoom(
      id: 801,
      name: "AI 질문 토론 클래스",
      joinCode: "PKAI01",
      battle: aiBattle,
      deadline: owner.deadline,
      memberCount: 32,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    var aiChatAlert = ClassAIChatFeature.State(room: aiRoom, battleID: -1_000_801, selectedOptionID: 1)
    aiChatAlert.isCompleted = true
    aiChatAlert.customAlert = .finalVote()
    let session = ClassMockChatSession()
    let battleID = await session.register(room: member)
    let previewRepository = MockClassRepository()
    let ownerMembers = try await previewRepository.fetchMembers(roomID: owner.id)
    let memberMembers = try await previewRepository.fetchMembers(roomID: member.id)

    func classTab(_ screen: ClassCoordinator.ClassScreen.State) -> AnyView {
      let repository: MockClassRepository
      if case let .myClasses(list) = screen {
        repository = MockClassRepository(rooms: list.rooms, availableRooms: [])
      } else {
        repository = previewRepository
      }
      var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
      state.classState.routes.push(screen)
      return AnyView(MainTabView(store: Store(initialState: state) {
        MainTabCoordinator()
          .dependency(\.classUseCase, repository)
          .dependency(\.classMockRepository, repository)
          .dependency(\.classMockChatSession, session)
          .dependency(\.classMockAudioPlayer, ClassMockAudioPlayer())
      }))
    }

    func chatFrame(_ number: Int, _ title: String, _ slug: String, _ state: ChatCoordinator.State) -> Frame {
      let store = Store(initialState: state) {
        ChatCoordinator()
          .dependency(\.battleUseCase, session)
          .dependency(\.perspectiveUseCase, session)
          .dependency(\.commentUseCase, session)
          .dependency(\.audioPlayer, ClassMockAudioPlayer())
          .dependency(\.analyticsUseCase, .testValue)
          .dependency(\.shareUseCase, .testValue)
      }
      let ready: @MainActor () -> Bool = {
        switch store.routes.last?.screen {
        case let .preVote(value)?:
          return value.battle != nil || value.detailLoadFailed
        case let .chatRoom(value)?:
          return value.scenario != nil || value.scenarioLoadFailed
        case let .comment(value)?:
          return !value.title.isEmpty
        default:
          return false
        }
      }
      return Frame(
        number: number,
        title: title,
        slug: slug,
        detail: "seeded member battle; async mock load",
        view: AnyView(ChatCoordinatorView(store: store)),
        ready: ready
      )
    }

    var chatRoom = ChatCoordinator.State(battleId: battleID)
    chatRoom.routes = [.root(.chatRoom(.init(battleId: battleID)), embedInNavigationView: true)]

    var aiRecommend = ClassRecommendFeature.State(filter: filter, mode: .aiQuestions)
    aiRecommend.questions = ClassAIQuestion.examples
    aiRecommend.selectedQuestionId = aiQuestion.id
    var existingRecommend = ClassRecommendFeature.State(filter: filter)
    existingRecommend.battles = ClassBattleSummary.mocks
    existingRecommend.selectedBattleId = ClassBattleSummary.mocks[0].id
    var ownerList = MyClassFeature.State()
    ownerList.rooms = ClassRoom.mocks
    var memberList = MyClassFeature.State()
    memberList.rooms = [member, .mockClosedSociety]

    func frame(_ number: Int, _ title: String, _ slug: String, _ detail: String, _ view: AnyView?) -> Frame {
      Frame(number: number, title: title, slug: slug, detail: detail, view: view, ready: nil)
    }

    return [
      frame(
        1,
        "AI 질문 추천",
        "ai-recommend",
        "selected first AI question",
        AnyView(ClassRecommendView(store: Store(initialState: aiRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        2,
        "AI 질문 설정",
        "ai-setting",
        "first AI question; empty class name",
        AnyView(ClassSettingView(store: Store(initialState: .init(aiQuestion: aiQuestion, filter: filter)) {
          ClassSettingFeature()
        }))
      ),
      frame(
        3,
        "홈",
        "home",
        "real Home tab; login and async data may limit content",
        AnyView(MainTabView(store: Store(initialState: .init()) { MainTabCoordinator() }))
      ),
      frame(
        4,
        "클래스 인트로",
        "intro",
        "real Class tab; intro hides tab bar",
        AnyView(MainTabView(store: Store(initialState: .init(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)) {
          MainTabCoordinator()
            .dependency(\.classUseCase, previewRepository)
            .dependency(\.classMockRepository, previewRepository)
        }))
      ),
      frame(
        5,
        "시작 방식",
        "start-method",
        "existing content initially selected",
        AnyView(ClassStartMethodView(store: Store(initialState: .init()) { ClassStartMethodFeature() }))
      ),
      frame(
        6,
        "주제와 조건",
        "topic",
        "Figma category selection: philosophy",
        AnyView(ClassTopicView(store: Store(initialState: topic) { ClassTopicFeature() }))
      ),
      frame(
        7,
        "클래스 공유",
        "share",
        "owner mock room",
        AnyView(ClassShareView(store: Store(initialState: .init(room: owner)) { ClassShareFeature() }))
      ),
      frame(
        8,
        "기존 배틀 설정",
        "existing-setting",
        "first mock battle",
        AnyView(ClassSettingView(store: Store(initialState: .init(battle: ClassBattleSummary.mocks[0])) {
          ClassSettingFeature()
        }))
      ),
      frame(
        9,
        "기존 배틀 추천",
        "existing-recommend",
        "selected first mock battle",
        AnyView(ClassRecommendView(store: Store(initialState: existingRecommend) { ClassRecommendFeature() }))
      ),
      frame(
        10,
        "이름 입력",
        "join-name",
        "member room preview",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .nickname, preview: member)) { ClassJoinFeature()
        }))
      ),
      frame(
        11,
        "코드 입력",
        "join-code",
        "empty code",
        AnyView(ClassJoinView(store: Store(initialState: .init(mode: .code)) { ClassJoinFeature() }))
      ),
      frame(
        12,
        "멤버 내 클래스",
        "member-classes",
        "two member rooms",
        classTab(.myClasses(memberList))
      ),
      frame(
        13,
        "멤버 클래스 상세",
        "member-detail",
        "open member room",
        classTab(.detail(.init(room: member)))
      ),
      frame(
        14,
        "멤버 목록",
        "member-list",
        "member room with mock members",
        classTab(.members(.init(
          room: member,
          members: memberMembers,
          currentMemberID: 2
        )))
      ),
      chatFrame(15, "댓글", "comment", .init(commentBattleId: battleID)),
      chatFrame(16, "최종 투표", "final-vote", .init(route: .finalVote(battleId: battleID))),
      chatFrame(17, "청취와 대화", "chat-room", chatRoom),
      chatFrame(18, "사전 투표", "pre-vote", .init(battleId: battleID)),
      frame(
        19,
        "멤버 개인 리포트",
        "member-report",
        "member room summary tab",
        classTab(.report(.init(room: member)))
      ),
      frame(
        20,
        "마감 배틀",
        "closed-battle",
        "closed member room",
        AnyView(ClassClosedBattleView(store: Store(initialState: .init(room: .mockClosedSociety)) {
          ClassClosedBattleFeature()
        }))
      ),
      frame(
        21,
        "운영자 내 클래스",
        "owner-classes",
        "three owner mock rooms",
        classTab(.myClasses(ownerList))
      ),
      frame(
        22,
        "운영자 클래스 상세",
        "owner-detail",
        "open owner room",
        classTab(.detail(.init(room: owner)))
      ),
      frame(
        23,
        "운영자 클래스 요약",
        "owner-dashboard",
        "preview home metrics",
        classTab(.ownerDashboard(.preview(room: owner)))
      ),
      frame(
        24,
        "운영자 멤버 목록",
        "owner-members",
        "owner room with mock members",
        classTab(.members(.init(
          room: owner,
          members: ownerMembers,
          currentMemberID: 1
        )))
      ),
      frame(
        25,
        "운영자 내 리포트",
        "owner-report",
        "preview report metrics",
        classTab(.ownerDashboard(.preview(room: owner, tab: .report)))
      ),
      frame(
        26,
        "최종 투표 안내",
        "final-vote-alert",
        "AI chat completed; final vote confirmation",
        AnyView(ClassAIChatView(store: Store(initialState: aiChatAlert) {
          ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase())
        }))
      ),
      frame(
        27,
        "AI 질문 대화",
        "ai-chat",
        "round one before Foundation Models response",
        AnyView(ClassAIChatView(store: Store(initialState: .init(
          room: aiRoom,
          battleID: -1_000_801,
          selectedOptionID: 1
        )) { ClassAIChatFeature().dependency(\.classAIChatUseCase, MockClassAIChatUseCase()) }))
      ),
      frame(
        28,
        "AI 질문 단일 투표",
        "ai-vote",
        "AI question mock room",
        AnyView(ClassAIVoteView(store: Store(initialState: .init(room: aiRoom, battleID: -1_000_801)) {
          ClassAIVoteFeature()
        }))
      ),
    ]
  }
}
