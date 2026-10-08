import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassMemberDetailFeature.self)
public struct ClassMemberDetailView: View {
  @Bindable public var store: StoreOf<ClassMemberDetailFeature>

  public init(store: StoreOf<ClassMemberDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          memberHeader
          summarySection
          commentSection
          replySection
          feedbackSection
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassMemberDetailView {
  var memberHeader: some View {
    HStack(spacing: 12) {
      PickeAvatarView(imageURL: nil, fallback: store.member.name, size: 40)
      VStack(alignment: .leading, spacing: 4) {
        Text(store.member.name)
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
        if let activity = store.activity {
          Text("댓글 \(activity.commentCount) · 대댓글 \(activity.replyCount)")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
        }
      }
      Spacer()
      if store.member.participationCount > 0 {
        Text("참여 완료").pickeBadge(.filled, size: .tag)
      }
    }
  }

  var summarySection: some View {
    section("참여 요약") {
      if let activity = store.activity {
        HStack(spacing: 8) {
          stance(activity.initialStance, label: "사전 선택")
          VStack(spacing: 4) {
            Image(systemName: activity.changedStance ? "arrow.right" : "equal")
            Text(activity.changedStance ? "입장 변경" : "입장 유지")
          }
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.gray300)
          stance(activity.finalStance, label: "사후 선택")
        }
        HStack(spacing: 0) {
          metric(activity.commentCount, label: "댓글")
          Rectangle().fill(.beige600).frame(width: 1, height: 36)
          metric(activity.replyCount, label: "대댓글")
          Rectangle().fill(.beige600).frame(width: 1, height: 36)
          metric(activity.receivedLikeCount, label: "받은 좋아요")
        }
        .padding(.vertical, 12)
        .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      } else {
        emptyCard("참여 기록이 아직 없어요.")
      }
    }
  }

  var commentSection: some View {
    section("남긴 댓글") {
      if let comment = store.activity?.comment {
        if store.activity?.commentOpinion != nil {
          Button { send(.commentTapped) } label: { activityCard(comment, showsChevron: true) }
            .buttonStyle(.plain)
        } else {
          activityCard(comment)
        }
      } else {
        emptyCard("남긴 댓글이 없어요.")
      }
    }
  }

  var replySection: some View {
    section("남긴 대댓글") {
      if let reply = store.activity?.reply {
        activityCard(reply)
      } else {
        emptyCard("남긴 대댓글이 없어요.")
      }
    }
  }

  var feedbackSection: some View {
    section("운영자 피드백") {
      VStack(alignment: .leading, spacing: 12) {
        if let feedback = store.activity?.feedback {
          Text(feedback)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray700)
        } else {
          Text("아직 작성된 피드백이 없어요.")
            .pretendardFont(.semiBold15)
            .foregroundStyle(.gray800)
          Text("참여 기록과 의견을 확인한 뒤 개별 피드백을 남겨주세요.")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
        }
        Button { send(.feedbackTapped) } label: {
          Text(store.activity?.feedback == nil ? "피드백 작성하기" : "피드백 수정하기")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .ctaButtonStyle(.primary, size: .medium, height: 42)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    }
  }

  func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  func stance(_ value: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label).pretendardFont(.regular13).foregroundStyle(.gray300)
      Text(value).pretendardFont(.semiBold15).foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }

  func metric(_ value: Int, label: String) -> some View {
    VStack(spacing: 4) {
      Text("\(value)").pretendardFont(.semiBold15).foregroundStyle(.gray800)
      Text(label).pretendardFont(.regular13).foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  func activityCard(_ text: String, showsChevron: Bool = false) -> some View {
    HStack(spacing: 8) {
      Text(text)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .multilineTextAlignment(.leading)
      Spacer(minLength: 0)
      if showsChevron {
        Image(systemName: "chevron.right").foregroundStyle(.gray300)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }

  func emptyCard(_ text: String) -> some View {
    Text(text)
      .pretendardFont(.regular13)
      .foregroundStyle(.gray300)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }
}

#if DEBUG
  #Preview("운영자 멤버 상세") {
    ClassMemberDetailView(store: Store(initialState: ClassMemberDetailFeature.State(
      room: ClassRoom.mocks[0],
      member: ClassOwnerMember(id: 1, name: "공은지", participationCount: 1),
      activity: .init(
        initialStance: "낮춰야 한다",
        finalStance: "교정이 우선이다",
        commentCount: 2,
        replyCount: 3,
        receivedLikeCount: 12,
        comment: "제도화가 무서운 건, 사회적 압력이 선택을 의무로 바꿀 수 있다는 거예요.",
        commentOpinion: ClassOwnerOpinion(
          id: 101,
          author: "공은지",
          text: "제도화가 무서운 건, 사회적 압력이 선택을 의무로 바꿀 수 있다는 거예요.",
          replyCount: 2
        ),
        reply: "다른 의견을 읽고 생각을 바꿨어요."
      )
    )) {
      ClassMemberDetailFeature()
    })
  }
#endif
