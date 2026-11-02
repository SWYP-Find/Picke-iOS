//
//  ClassFigmaParityCaptureTests.swift
//  PickeTests
//
//  Created by Picke on 11/2/26.
//

import ClassDomainInterface
import ComposableArchitecture
import FeatureAssembly
@testable import Picke
import PickeDesignKit
import SwiftUI
import UIKit
import XCTest

/// Run explicitly with PICKE_CLASS_VISUAL_AUDIT=1. Captures the real Class route
/// screens at 1x and the Figma frame size so they can be diffed against the
/// FigmaClassAudit plugin export. These images are evidence, not snapshot assertions.
final class ClassFigmaParityCaptureTests: XCTestCase {
  @MainActor
  func testCaptureClassFigmaParityFrames() async throws {
    guard ProcessInfo.processInfo.environment["PICKE_CLASS_VISUAL_AUDIT"] == "1" else {
      throw XCTSkip("Set PICKE_CLASS_VISUAL_AUDIT=1 to capture Class Figma parity frames")
    }
    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("ClassFigmaParity", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let phone = CGSize(width: 375, height: 812)
    try await save(flowView(step: .none, selectedOptionID: 2), size: phone, name: "13337-56744-pre-vote", in: directory)
    try await save(
      flowView(step: .ttsListening, selectedOptionID: 2),
      size: phone,
      name: "13337-56966-tts",
      in: directory
    )
    try await save(
      flowView(step: .postVote, selectedOptionID: 2),
      size: phone,
      name: "13337-57185-final-vote",
      in: directory
    )
    try await save(
      flowView(step: .completed, selectedOptionID: 2),
      size: phone,
      name: "13384-57726-opinion",
      in: directory
    )
    try await save(reportView(), size: CGSize(width: 402, height: 1090), name: "13757-17445-result", in: directory)
  }
}

private extension ClassFigmaParityCaptureTests {
  var room: ClassRoom {
    let source = ClassRoom.mockClosedSociety
    return ClassRoom(
      id: source.id,
      name: source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: source.deadline,
      memberCount: source.memberCount,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: source.ownerParticipates,
      memberCapacity: source.memberCapacity
    )
  }

  @MainActor
  func flowView(
    step: ClassBattleStep,
    selectedOptionID: Int
  ) -> AnyView {
    var state = ClassBattleFlowFeature.State()
    state.room = room
    state.viewState = .loaded
    // A pending load request keeps onAppear from replacing the seeded state with network calls.
    state.loadRequestID = UUID()
    state.selectedOptionID = selectedOptionID
    state.session = ClassBattleSession(
      classID: room.id,
      myRole: .member,
      closeAt: Date(timeIntervalSince1970: 1_790_154_000),
      closed: false,
      commentRequired: true,
      canParticipate: true,
      participationCompleted: false,
      battle: ClassBattleDetail(
        id: 10,
        title: "촉법소년 연령을 낮춰야 할까?",
        summary: "날로 잔혹해지는 청소년 범죄, 당신은 강력한 처벌을 원하십니까, 아니면 기회와 교정을 원하십니까?",
        thumbnailURL: nil,
        description: "날로 잔혹해지는 청소년 범죄, 당신은 강력한 처벌을 원하십니까, 아니면 기회와 교정을 원하십니까?",
        shareURL: nil,
        userVoteStatus: nil,
        currentStep: step,
        participantsCount: 28,
        audioDuration: 268,
        options: [
          .init(id: 1, label: "A", title: "예술이다", stance: "예술이다", representative: "사르트르", imageURL: nil),
          .init(id: 2, label: "B", title: "변기는 변기다", stance: "변기는 변기다", representative: "플라톤", imageURL: nil),
        ]
      ),
      midVoteEnabled: false
    )
    state.hasPublishedPerspective = false
    state.voteHistory = ClassVoteHistory(
      battleTitle: "촉법소년 연령을 낮춰야 할까?",
      preVote: .init(optionID: 1, label: "A", title: "예술이다"),
      postVote: .init(optionID: 2, label: "B", title: "변기는 변기다"),
      status: step,
      opinionChanged: true
    )
    state.isAudioReady = true
    state.isPlaying = true
    state.audioDuration = 268
    state.currentTime = 127
    state.transcript = [
      .init(id: 0, startTime: 0, speakerName: "한나 아렌트", speakerImageURL: nil,
            text: "범죄의 잔혹함과 지능화에 나이는 더 이상 핑계가 될 수 없습니다!", side: "A"),
      .init(id: 1, startTime: 10, speakerName: "한나 아렌트", speakerImageURL: nil,
            text: "'촉법소년'이라는 제도가 오히려 아이들에게 법을 비웃고 범죄를 저지를 면죄부가 되고 있습니다.", side: "A"),
      .init(id: 2, startTime: 20, speakerName: "한나 아렌트", speakerImageURL: nil,
            text: "피해자의 눈물을 닦아주고 사법 정의를 세우려면 촉법 연령을 낮춰 단호하게 처벌해야 합니다.", side: "A"),
      .init(id: 3, startTime: 40, speakerName: "루소", speakerImageURL: nil,
            text: "아렌트 선생, 청소년은 아직 뇌와 도덕성이 성숙하지 못한 존재입니다!", side: "B"),
      .init(id: 4, startTime: 60, speakerName: "루소", speakerImageURL: nil,
            text: "성인과 똑같은 엄벌의 잣대를 대는 것은 사회가 아이들의 선도 가능성을 포기하는 것과 같습니다.", side: "B"),
      .init(id: 5, startTime: 80, speakerName: "루소", speakerImageURL: nil,
            text: "전과자라는 낙인을 찍어 감옥에 보내는 대신, 교육과 환경 개선을 통해 사회로 돌아오게 돕는 것이 국가의 의무입니다.",
            side: "B"),
      .init(id: 6, startTime: 120, speakerName: "한나 아렌트", speakerImageURL: nil,
            text: "처벌받지 않는 악은 반드시 재범으로 이어집니다.", side: "A"),
    ]
    state.voteStats = ClassVoteStats(
      options: [
        .init(id: 1, title: "예술이다", imageURL: nil, voteCount: 119, ratio: 59.5),
        .init(id: 2, title: "변기는 변기다", imageURL: nil, voteCount: 81, ratio: 40.5),
      ],
      totalCount: 200,
      updatedAt: .now
    )
    let author = ClassPerspectiveAuthor(
      userTag: "raccoon",
      nickname: "사유하는 라쿤",
      characterType: nil,
      characterImageURL: nil
    )
    let option = ClassPerspectiveOption(id: 2, label: "B", title: "변기는 변기다", stance: "변기는 변기다")
    state.perspectives = (0 ..< 3).map { index in
      ClassPerspectiveItem(
        id: 100 + index,
        author: author,
        option: option,
        content: "제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요. 네덜란드 사례를 보면 우려가 현실이 되고 있죠. 제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요.",
        likeCount: 1340,
        commentCount: 23,
        isLiked: false,
        isMyPerspective: false,
        status: nil,
        createdAt: Date().addingTimeInterval(-120)
      )
    }
    let store = Store(initialState: state) { ClassBattleFlowFeature() }
    return AnyView(ClassBattleFlowView(store: store))
  }

  @MainActor
  func reportView() -> AnyView {
    let source = ClassRoom.mockClosedSociety
    let owner = ClassRoom(
      id: source.id,
      name: source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: source.deadline,
      memberCount: source.memberCount,
      role: .owner,
      status: .closed,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: source.ownerParticipates,
      memberCapacity: source.memberCapacity
    )
    var state = ClassReportFeature.State(room: owner, instanceID: UUID())
    state.sourceViewState = .ready
    state.insight = ClassAIInsight(
      text: "처음에는 뫼르소의 태도를 비난할 수 있다는 의견이 많았지만, 대화 후에는 행동과 감정을 분리해서 봐야 한다는 의견이 늘어났어요.",
      highlights: [
        .init(content: "슬픔을 겉으로 드러내지 않는다고 해서 타인을 사랑하지 않는다고 판단할 수는 없다고 생각해요."),
        .init(content: "감정은 개인의 자유지만, 사회적 관계에서는 최소한의 공감 표현도 필요하다고 생각해요."),
      ]
    )
    state.classResult = ClassResult(
      classID: owner.id,
      closed: true,
      closeAt: owner.deadline,
      stats: .init(
        activeMemberCount: 32,
        completedCount: 28,
        participationRate: 87.5,
        commentWriterCount: 24,
        commentRate: 75,
        postVoteCount: 28,
        options: [
          .init(id: 1, title: "낮춰야한다", preVoteCount: 18, postVoteCount: 18, postVoteRatio: 64),
          .init(id: 2, title: "교정이 우선이다", preVoteCount: 10, postVoteCount: 10, postVoteRatio: 36),
        ]
      ),
      myReportState: nil,
      insightState: "SUCCEEDED"
    )
    let store = Store(initialState: state) { ClassReportFeature() }
    return AnyView(ClassReportView(store: store))
  }

  @MainActor
  func save(
    _ view: AnyView,
    size: CGSize,
    name: String,
    in directory: URL
  ) async throws {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: view.environment(\.colorScheme, .light))
    window.rootViewController = host
    window.frame = CGRect(origin: .zero, size: size)
    window.makeKeyAndVisible()
    // A window shorter than the screen sits above the home indicator, so mirror a device bottom safe area.
    host.additionalSafeAreaInsets.bottom = max(0, 34 - window.safeAreaInsets.bottom)
    defer { window.isHidden = true }
    host.view.frame = window.bounds
    host.view.layoutIfNeeded()
    // Report charts animate after data arrives.
    try await Task.sleep(for: .milliseconds(1200))
    host.view.layoutIfNeeded()
    CATransaction.flush()
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    try XCTUnwrap(image.pngData()).write(to: directory.appendingPathComponent(name + ".png"))
    let attachment = XCTAttachment(image: image)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
