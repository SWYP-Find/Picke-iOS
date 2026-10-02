@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassOwnerDetailTests {
  @Test
  func 멤버_상세는_전달받은_멤버를_표시하고_활동_기록을_추측하지_않는다() {
    let member = ClassOwnerMember(id: 42, name: "공은지", participationCount: 1)
    let state = ClassMemberDetailFeature.State(room: ClassRoom.mocks[0], member: member)

    #expect(state.member == member)
    #expect(state.activity == nil)
  }

  @Test
  func 대댓글_상세는_선택한_의견을_유지하고_임의의_답글을_만들지_않는다() {
    let opinion = ClassOwnerOpinion(id: 7, author: "공은지", text: "제 의견입니다.", replyCount: 3)
    let state = ClassReplyDetailFeature.State(room: ClassRoom.mocks[0], opinion: opinion)

    #expect(state.opinion == opinion)
    #expect(state.replies.isEmpty)
    #expect(state.viewState == .unavailable)
  }

  @Test
  func 실제_답글이_없을_때만_빈_상태를_표시한다() {
    let opinion = ClassOwnerOpinion(id: 8, author: "공은지", text: "제 의견입니다.", replyCount: 0)
    let state = ClassReplyDetailFeature.State(room: ClassRoom.mocks[0], opinion: opinion)

    #expect(state.viewState == .empty)
  }

  @Test
  func 멤버_댓글을_누르면_선택한_내용을_전달한다() async {
    let member = ClassOwnerMember(id: 42, name: "공은지", participationCount: 1)
    let opinion = ClassOwnerOpinion(id: 101, author: "공은지", text: "제 의견입니다.", replyCount: 1)
    let activity = ClassMemberDetailFeature.State.Activity(
      initialStance: "찬성",
      finalStance: "찬성",
      commentCount: 1,
      replyCount: 2,
      receivedLikeCount: 0,
      comment: "제 의견입니다.",
      commentOpinion: opinion
    )
    #expect(!activity.changedStance)
    let store = TestStore(initialState: ClassMemberDetailFeature.State(
      room: ClassRoom.mocks[0], member: member, activity: activity
    )) {
      ClassMemberDetailFeature()
    }

    await store.send(.view(.commentTapped))
    await store.receive(\.delegate, .commentSelected(opinion))
  }
}
