import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassFeedbackComposeFeature.self)
public struct ClassFeedbackComposeView: View {
  @Bindable public var store: StoreOf<ClassFeedbackComposeFeature>

  public init(store: StoreOf<ClassFeedbackComposeFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 12) {
            PickeAvatarView(imageURL: nil, fallback: store.memberName, size: 40)
            VStack(alignment: .leading, spacing: 4) {
              Text(store.memberName)
                .pretendardFont(family: .SemiBold, size: 16)
                .foregroundStyle(.gray800)
              Text("운영자 피드백")
                .pretendardFont(family: .Medium, size: 12)
                .foregroundStyle(.gray300)
            }
          }
          feedbackEditor
          HStack(spacing: 8) {
            Button { send(.cancelTapped) } label: {
              Text("취소").frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .ctaButtonStyle(.secondary, size: .large, height: 52)

            Button { send(.submitTapped) } label: {
              Text("등록").frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .ctaButtonStyle(.primary, size: .large, height: 52)
            .disabled(store.feedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .alert("전송 준비 중", isPresented: $store.showUnavailableAlert) {
      Button("확인", role: .cancel) {}
    } message: {
      Text("서버 연동 전이라 피드백을 전송할 수 없습니다.")
    }
  }
}

private extension ClassFeedbackComposeView {
  var feedbackEditor: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("운영자 피드백")
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.gray800)
        Spacer()
      }
      TextEditor(text: $store.feedback)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .scrollContentBackground(.hidden)
        .padding(8)
        .frame(height: 280)
        .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
        .overlay(alignment: .topLeading) {
          if store.feedback.isEmpty {
            Text("학생에게 전할 피드백을 작성해주세요.")
              .pretendardFont(.regular13)
              .foregroundStyle(.gray300)
              .padding(.horizontal, 12)
              .padding(.top, 16)
              .allowsHitTesting(false)
          }
        }
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
    }
  }
}
