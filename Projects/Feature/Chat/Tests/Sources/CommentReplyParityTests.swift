//
//  CommentReplyParityTests.swift
//  ChatTests
//
//  Created by Picke on 11/10/26.
//

@testable import Chat
import CommentDomainInterface
import ComposableArchitecture
import Foundation
import PerspectiveDomainInterface
import Testing

/// Android `CommentScreen`/`CommentViewModel` 과 맞춘 댓글 화면 동작.
@MainActor
struct CommentReplyParityTests {
  private func state(parentIsMine: Bool = false) -> CommentReplyFeature.State {
    CommentReplyFeature.State(
      perspectiveId: 1,
      parentComment: CommentItem(
        perspectiveId: 1,
        author: "원작성자",
        timeAgo: "1분 전",
        option: .a,
        content: "원본",
        replyCount: 1,
        likeCount: 2,
        isMine: parentIsMine,
        createdOrder: 0
      )
    )
  }

  @Test
  func ownParentLikeShowsPerspectiveToast() async {
    let store = TestStore(initialState: state(parentIsMine: true)) { CommentReplyFeature() }

    await store.send(.view(.parentLikeTapped)) {
      $0.toastMessage = "본인이 쓴 관점에는 좋아요를 누를 수 없습니다."
    }
  }

  @Test
  func ownReplyLikeShowsReplyToast() async {
    var initial = state()
    let reply = CommentReplyItem(
      commentId: 9,
      author: "나",
      timeAgo: "방금 전",
      option: .a,
      content: "답글",
      likeCount: 0,
      isMine: true,
      createdOrder: 0
    )
    initial.replies = [reply]
    let store = TestStore(initialState: initial) { CommentReplyFeature() }

    await store.send(.view(.replyLikeTapped(reply.id))) {
      $0.toastMessage = "본인이 쓴 댓글에는 좋아요를 누를 수 없습니다."
    }
  }

  @Test
  func parentFailureShowsFailedSectionAndToast() async {
    let store = TestStore(initialState: state()) { CommentReplyFeature() }

    await store.send(.inner(.parentResponse(.failure(.noData)))) {
      $0.loadFailed = true
      $0.toastMessage = "정보를 불러오지 못했어요"
    }
  }

  @Test
  func reportResultsShowAndroidToasts() async {
    let store = TestStore(initialState: state()) { CommentReplyFeature() }

    await store.send(.inner(.reportResponse(.success(true)))) {
      $0.toastMessage = "신고가 정상 접수되었습니다."
    }
    await store.send(.inner(.reportResponse(.failure(.alreadyReported)))) {
      $0.toastMessage = "이미 신고한 사용자입니다."
    }
  }

  @Test
  func inputPlaceholderFollowsAndroid() {
    var current = state()
    #expect(current.inputPlaceholder == "댓글을 남겨보세요...")
    current.editingCommentId = 3
    #expect(current.inputPlaceholder == "수정할 내용을 입력해주세요...")
  }
}
