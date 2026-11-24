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
      $0.perspectiveOpinions = [ClassReportOpinion(
        id: "77",
        kind: .comment,
        body: "내 생각",
        stance: "찬성",
        likeCount: 4,
        replyCount: 2,
        authorName: "나"
      )]
    }
    #expect(store.state.comments.count == 1)
  }

  @Test
  func 서버_내_의견은_검수_중과_거절만_빼고_알_수_없는_상태는_공개로_본다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.isLoading = true
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.perspectivesResponse(.success([
      perspective(id: 1, status: "PUBLISHED"),
      perspective(id: 2, status: "PENDING"),
      perspective(id: 3, status: "rejected"),
      perspective(id: 4, status: nil),
      perspective(id: 5, status: "HIDDEN_BY_ADMIN"),
    ]))))

    #expect(store.state.perspectiveOpinions.map(\.id) == ["1", "4", "5"])
  }

  @Test
  func 내_활동_댓글은_원_의견_제목과_내_이름을_가진_대댓글로_옮긴다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.myDisplayNameResponse(.success("민지"))))
    await store.receive(\.async.fetchReplyPage)
    await store.send(.inner(.replyPageResponse(cursor: nil, .success(activity(ids: [71], next: "c-2")))))

    #expect(store.state.replyOpinions == [ClassReportOpinion(
      id: "reply-71",
      kind: .reply,
      body: "댓글 71",
      likeCount: 2,
      authorName: "민지",
      parent: ClassReportReplyContext(body: "원 의견 71")
    )])
    #expect(store.state.replies.first?.replyAuthorLabel == "민지의 답글")
    #expect(store.state.replies.first?.parentStanceLabel == nil)
    #expect(store.state.nextCursor == "c-2")
    #expect(store.state.canLoadMoreReplies)
  }

  @Test
  func 표시_이름이_비면_나로_표시한다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.myDisplayName = ""
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.replyPageResponse(cursor: nil, .success(activity(ids: [71], next: nil)))))

    #expect(store.state.replies.first?.replyAuthorLabel == "나의 답글")
  }

  @Test
  func 의견과_대댓글_응답은_도착_순서와_무관하게_서로를_덮어쓰지_않는다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.isLoading = true
    state.myDisplayName = "민지"
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.replyPageResponse(cursor: nil, .success(activity(ids: [71], next: nil)))))
    await store.send(.inner(.perspectivesResponse(.success([perspective(id: 1, status: nil)]))))

    #expect(store.state.comments.map(\.opinion.id) == ["1"])
    #expect(store.state.replies.map(\.opinion.id) == ["reply-71"])
    #expect(!store.state.isEmpty)
  }

  @Test
  func 목록_끝에서_커서로_다음_대댓글을_이어_붙이고_첫_페이지는_교체한다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.myDisplayName = "민지"
    let store = TestStore(initialState: state) {
      ClassMyOpinionsFeature()
    } withDependencies: {
      $0.classResultUseCase = ActivityStub(pages: ["c-2": activity(ids: [72], next: nil)])
    }
    store.exhaustivity = .off

    await store.send(.inner(.replyPageResponse(cursor: nil, .success(activity(ids: [71], next: "c-2")))))
    await store.send(.view(.repliesEndReached))
    await store.receive(\.async.fetchReplyPage)
    #expect(store.state.isLoadingMore)
    await store.receive(\.inner.replyPageResponse)

    #expect(store.state.replyOpinions.map(\.id) == ["reply-71", "reply-72"])
    #expect(!store.state.canLoadMoreReplies)
    #expect(!store.state.isLoadingMore)

    await store.send(.inner(.replyPageResponse(cursor: nil, .success(activity(ids: [71], next: nil)))))
    #expect(store.state.replyOpinions.map(\.id) == ["reply-71"])
  }

  @Test
  func 내_활동_조회에_실패하면_의견은_유지하고_토스트를_띄운다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.perspectiveOpinions = [ClassReportOpinion(id: "1", kind: .comment, body: "내 의견")]
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.replyPageResponse(cursor: nil, .failure(.network("실패")))))
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
    #expect(store.state.perspectiveOpinions.count == 1)

    await store.send(.view(.toastShown))
    #expect(store.state.toastMessage == nil)

    await store.send(.inner(.myDisplayNameResponse(.failure(.network("실패")))))
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
  }

  @Test
  func 다음_대댓글_페이지_조회에_실패하면_더_불러오기를_멈춘다() async {
    var state = ClassMyOpinionsFeature.State()
    state.classID = 31
    state.nextCursor = "c-2"
    state.hasNext = true
    state.isLoadingMore = true
    let store = TestStore(initialState: state) { ClassMyOpinionsFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.replyPageResponse(cursor: "c-2", .failure(.network("실패")))))

    #expect(!store.state.hasNext)
    #expect(!store.state.canLoadMoreReplies)
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
  }

  private func perspective(
    id: Int,
    status: String?
  ) -> ClassPerspectiveItem {
    ClassPerspectiveItem(
      id: id,
      author: .init(userTag: "member", nickname: "나", characterType: nil, characterImageURL: nil),
      option: .init(id: 1, label: "A", title: "찬성", stance: "찬성"),
      content: "의견 \(id)",
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isMyPerspective: true,
      status: status,
      createdAt: .now
    )
  }

  private func activity(
    ids: [Int],
    next: String?
  ) -> ClassMyActivity {
    ClassMyActivity(
      classID: 31,
      receivedLikeCount: 0,
      commentCount: ids.count,
      comments: ids.map {
        ClassMyActivityComment(
          id: $0,
          perspectiveID: $0 + 100,
          perspectiveTitle: "원 의견 \($0)",
          stance: "",
          content: "댓글 \($0)",
          likeCount: 2,
          createdAt: nil
        )
      },
      nextCursor: next,
      hasNext: next != nil
    )
  }

  private struct ActivityStub: ClassResultInterface {
    let pages: [String: ClassMyActivity]

    func fetchResult(roomID _: Int) async throws -> ClassResult {
      throw ClassError.network("사용하지 않음")
    }

    func fetchPersonalResult(roomID _: Int) async throws -> ClassAIPersonalFeedback {
      throw ClassAIFeedbackError.temporarilyUnavailable
    }

    func fetchInsight(roomID _: Int) async throws -> ClassAIInsight {
      throw ClassAIFeedbackError.temporarilyUnavailable
    }

    func retryInsight(roomID _: Int) async throws {}

    func fetchMyActivity(
      roomID _: Int,
      cursor: String?
    ) async throws -> ClassMyActivity {
      guard let cursor, let page = pages[cursor] else { throw ClassError.network("페이지 없음") }
      return page
    }
  }
}
