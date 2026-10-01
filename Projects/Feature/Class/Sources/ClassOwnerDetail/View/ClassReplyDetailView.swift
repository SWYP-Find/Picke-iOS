import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassReplyDetailFeature.self)
public struct ClassReplyDetailView: View {
  public let store: StoreOf<ClassReplyDetailFeature>

  public init(store: StoreOf<ClassReplyDetailFeature>) {
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
        VStack(spacing: 12) {
          ForEach(store.replies) { reply in
            replyCard(reply)
          }
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

private extension ClassReplyDetailView {
  @ViewBuilder
  func replyCard(_ reply: ClassReplyDetailFeature.State.Reply) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        PickeAvatarView(imageURL: nil, fallback: reply.author, size: 32)
        Text(reply.author)
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.gray800)
        Spacer()
        Text(reply.date)
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.gray300)
      }
      Text(reply.body)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 12) {
        Label("12", systemImage: "heart")
        Label("답글", systemImage: "bubble")
      }
      .pretendardFont(.regular13)
      .foregroundStyle(.gray300)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}
