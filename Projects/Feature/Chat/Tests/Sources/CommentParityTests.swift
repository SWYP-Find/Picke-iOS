//
//  CommentParityTests.swift
//  ChatTests
//
//  Created by Picke on 11/10/26.
//

import BattleDomainInterface
@testable import Chat
import CommentDomainInterface
import ComposableArchitecture
import Foundation
import PerspectiveDomainInterface
import Testing

/// Android `PerspectiveScreen`/`PerspectiveViewModel` 과 맞춘 관점 목록 동작.
@MainActor
struct CommentParityTests {
  private func comment(
    id: Int,
    isMine: Bool = false
  ) -> CommentItem {
    CommentItem(
      perspectiveId: id,
      author: "작성자\(id)",
      timeAgo: "1분 전",
      option: .a,
      content: "내용",
      replyCount: 0,
      likeCount: 3,
      isMine: isMine,
      createdOrder: id
    )
  }

  @Test
  func ownPerspectiveLikeShowsToastWithoutRequest() async {
    var state = CommentFeature.State(battleId: 1)
    let mine = comment(id: 7, isMine: true)
    state.comments = [mine]
    let store = TestStore(initialState: state) { CommentFeature() }

    await store.send(.view(.commentRow(id: mine.id, action: .like))) {
      $0.toastMessage = "본인이 쓴 관점에는 좋아요를 누를 수 없습니다."
    }
    await store.send(.view(.toastShown)) {
      $0.toastMessage = nil
    }
  }

  @Test
  func lastCommentDoesNotLoadMoreWithoutNextPage() async {
    var state = CommentFeature.State(battleId: 1)
    state.comments = [comment(id: 1)]
    state.hasNext = false
    state.nextCursor = "c"
    let store = TestStore(initialState: state) { CommentFeature() }

    await store.send(.view(.lastCommentAppeared))
  }

  @Test
  func lastCommentDoesNotLoadMoreWhileLoading() async {
    var state = CommentFeature.State(battleId: 1)
    state.comments = [comment(id: 1)]
    state.hasNext = true
    state.nextCursor = "c"
    state.isLoadingComments = true
    let store = TestStore(initialState: state) { CommentFeature() }

    await store.send(.view(.lastCommentAppeared))
  }

  @Test
  func nextPageAppendsWithoutDuplicatesAndStopsOnEmptyPage() async {
    var state = CommentFeature.State(battleId: 1)
    state.comments = [comment(id: 1)]
    let store = TestStore(initialState: state) { CommentFeature() }
    store.exhaustivity = .off

    let page = BattlePerspectivePage(items: [], nextCursor: "next", hasNext: true)
    await store.send(.inner(.perspectivesResponse(.success(page), reset: false))) {
      $0.hasNext = false
      $0.nextCursor = "next"
    }
    #expect(store.state.comments.count == 1)
  }

  @Test
  func reportResultsShowAndroidToasts() async {
    let store = TestStore(initialState: CommentFeature.State(battleId: 1)) { CommentFeature() }

    await store.send(.inner(.reportResponse(.success(true)))) {
      $0.toastMessage = "신고가 정상 접수되었습니다."
    }
    await store.send(.inner(.reportResponse(.failure(.alreadyReported)))) {
      $0.toastMessage = "이미 신고한 사용자입니다."
    }
    await store.send(.inner(.reportResponse(.failure(.serverError(500))))) {
      $0.toastMessage = "요청을 처리하지 못했어요"
    }
  }

  @Test
  func firstVoteStatsFailureShowsFailedSectionAndToast() async {
    let store = TestStore(initialState: CommentFeature.State(battleId: 1)) { CommentFeature() }

    await store.send(.inner(.voteStatsResponse(.failure(.noData)))) {
      $0.hasLoadedHeader = true
      $0.headerLoadFailed = true
      $0.toastMessage = "정보를 불러오지 못했어요"
    }
  }

  @Test
  func labelsFollowAndroidStrings() {
    var state = CommentFeature.State(battleId: 1)
    #expect(state.changeBadgeTitle == "생각이 동일해요")
    #expect(state.navigationTitle == "관점 남기기")
    #expect(state.inputPlaceholder == "의견을 남겨보세요...")
    state.editingPerspectiveId = 3
    #expect(state.inputPlaceholder == "수정할 내용을 입력해주세요...")
    state.selectedFilter = .optionA
    #expect(state.emptyMessage == "아직 작성된 \"\(state.voteSummary.optionA.title)\" 관점이 없습니다")
    #expect(VoteOptionSummary(label: "A", title: "", representative: "", percentage: 0.59).rateLabel == "59%")
    #expect(VoteOptionSummary(label: "A", title: "", representative: "", percentage: 0.595).rateLabel == "59.5%")
  }
}
