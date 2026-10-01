import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassMemberDetailFeature.self)
public struct ClassMemberDetailView: View {
  public let store: StoreOf<ClassMemberDetailFeature>

  public init(store: StoreOf<ClassMemberDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)
      Text("예시 데이터")
        .pretendardFont(.medium10)
        .foregroundStyle(.gray300)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)

      ScrollView {
        VStack(spacing: 16) {
          memberHeader
          summarySection
          activitySection
          feedbackSection
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
  }
}

private extension ClassMemberDetailView {
  var memberHeader: some View {
    HStack(spacing: 12) {
      PickeAvatarView(imageURL: nil, fallback: store.memberName, size: 40)
      VStack(alignment: .leading, spacing: 4) {
        Text(store.memberName)
          .pretendardFont(family: .SemiBold, size: 16)
          .foregroundStyle(.gray800)
        Text("클래스 멤버")
          .pretendardFont(family: .Medium, size: 12)
          .foregroundStyle(.gray300)
      }
      Spacer()
    }
    .padding(.vertical, 12)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige600).frame(height: 1)
    }
  }

  var summarySection: some View {
    detailSection("참여 요약", trailing: "총 47회 참여") {
      HStack(spacing: 0) {
        metric(value: store.participationRate, label: "참여율")
        separator
        metric(value: "28회", label: "배틀 참여")
        separator
        metric(value: "19회", label: "미참여")
      }
      .padding(.vertical, 12)
    }
  }

  var activitySection: some View {
    VStack(spacing: 16) {
      detailSection("남긴 댓글", trailing: "총 47회 참여") {
        Button { send(.commentTapped) } label: {
          activityCard(
            title: "낮춰야 한다",
            body: "제도화가 무서운 건, 사회적 압력이 선택을 의무로 바꿀 수 있다는 거예요.",
            icon: "chevron.right"
          )
        }
        .buttonStyle(.plain)
      }

      detailSection("남긴 대댓글", trailing: "총 47회 참여") {
        Button { send(.replyTapped) } label: {
          VStack(alignment: .leading, spacing: 8) {
            Text("토론을 들으면서 처벌만으로는 해결되지 않는 점을 이해하게 됐어요.")
              .pretendardFont(.regular13)
              .foregroundStyle(.gray700)
              .multilineTextAlignment(.leading)
            Text("26.09.23. 14:02")
              .pretendardFont(family: .SemiBold, size: 10)
              .foregroundStyle(.gray300)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
          .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
        }
        .buttonStyle(.plain)
      }
    }
  }

  var feedbackSection: some View {
    detailSection("운영자 피드백", trailing: "총 47회 참여") {
      VStack(alignment: .leading, spacing: 12) {
        Text("처음에는 처벌 기준에 집중했지만, 토론 후 다른 관점을 받아들이고 자신의 생각을 바꾼 과정이 잘 드러났어요.")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
          .lineLimit(3)
        Button { send(.feedbackTapped) } label: {
          Text("피드백 작성")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .ctaButtonStyle(.primary, size: .medium, height: 42)
      }
    }
  }

  @ViewBuilder
  func detailSection(
    _ title: String,
    trailing: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.gray800)
        Spacer()
        Text(trailing)
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.gray300)
      }
      content()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func metric(value: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(value).pretendardFont(.semiBold15).foregroundStyle(.gray800)
      Text(label).pretendardFont(.regular13).foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  var separator: some View {
    Rectangle().fill(.beige600).frame(width: 1, height: 47)
  }

  @ViewBuilder
  func activityCard(title: String, body: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title).pickeBadge(.filled, size: .tag)
        Text(body)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
          .multilineTextAlignment(.leading)
        HStack(spacing: 12) {
          Label("1,340", systemImage: "heart")
          Label("23", systemImage: "bubble")
        }
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
      }
      Spacer(minLength: 0)
      Image(systemName: icon)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.gray300)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}
