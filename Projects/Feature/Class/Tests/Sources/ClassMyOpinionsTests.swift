//
//  ClassMyOpinionsTests.swift
//  ClassTests
//
//  Created by Picke on 10/17/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassMyOpinionsTests {
  @Test
  func 명시적_목록은_종류별로_구분하고_원래_순서를_유지한다() {
    var state = ClassMyOpinionsFeature.State()
    state.opinions = MockClassReport.figmaMyOpinions.resolvedOpinions

    #expect(state.comments.map(\.index) == [0])
    #expect(state.replies.map(\.index) == [1, 2, 3, 4])
    #expect(state.unspecified.isEmpty)
    #expect(!state.isEmpty)
  }

  @Test
  func 같은_원본_ID와_본문도_스냅샷_행마다_다른_식별자를_갖는다() {
    let duplicate = ClassReportOpinion(id: "same", kind: .comment, body: "같은 의견")
    var state = ClassMyOpinionsFeature.State()
    state.opinions = [duplicate, duplicate]

    #expect(state.comments.map(\.id) == [0, 1])
    #expect(state.comments.map(\.accessibilityID) == ["class-my-opinion-0", "class-my-opinion-1"])
  }

  @Test
  func 명시적_빈_목록은_비어_있고_기존_문자열은_분류되지_않은_의견으로_남는다() {
    var state = ClassMyOpinionsFeature.State()
    state.opinions = []
    #expect(state.isEmpty)

    let legacy = ClassReport(
      texts: [:],
      myOpinions: ["반복", "반복"],
      initialVoteLeading: 0,
      finalVoteLeading: 0,
      layout: .summary
    )
    state.opinions = legacy.resolvedOpinions
    #expect(state.comments.isEmpty)
    #expect(state.replies.isEmpty)
    #expect(state.unspecified.map(\.index) == [0, 1])
    #expect(state.unspecified.map(\.opinion.body) == ["반복", "반복"])
  }

  @Test
  func 뒤로가기는_코디네이터에_닫기만_전달한다() async {
    let store = TestStore(initialState: ClassMyOpinionsFeature.State()) {
      ClassMyOpinionsFeature()
    }
    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 서버_내_의견은_내용과_반응_수를_화면_행으로_옮긴다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.isLoading = true
    let item = ClassPerspectiveItem(
      id: 77,
      author: .init(userTag: "member", nickname: "나", characterType: nil, characterImageURL: nil),
      option: .init(id: 1, label: "A", title: "찬성", stance: "찬성"),
      content: "내 생각",
      likeCount: 4,
      commentCount: 2,
      isLiked: false,
      isMyPerspective: true,
      status: nil,
      createdAt: .now
    )
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    await store.send(.inner(.perspectivesResponse(.success([item])))) {
      $0.isLoading = false
      $0.opinions = [ClassReportOpinion(
        id: "77",
        kind: .unspecified,
        body: "내 생각",
        stance: "찬성",
        likeCount: 4,
        replyCount: 2,
        authorName: "나"
      )]
    }
    #expect(store.state.unspecified.count == 1)
  }
}
