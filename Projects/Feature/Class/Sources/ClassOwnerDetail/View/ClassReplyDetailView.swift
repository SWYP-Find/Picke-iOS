import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassReplyDetailFeature.self)
public struct ClassReplyDetailView: View {
  @Bindable public var store: StoreOf<ClassReplyDetailFeature>

  public init(store: StoreOf<ClassReplyDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)
      ScrollView {
        VStack(spacing: 12) {
          if let opinion = store.opinion {
            VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 8) {
                PickeAvatarView(imageURL: nil, fallback: opinion.author, size: 36)
                Text(opinion.author)
                  .pretendardFont(.semiBold15)
                  .foregroundStyle(.gray800)
                Spacer()
              }
              Text(opinion.text)
                .pretendardFont(.regular13)
                .foregroundStyle(.gray700)
                .frame(maxWidth: .infinity, alignment: .leading)
              Label("\(opinion.replyCount)", systemImage: "bubble")
                .pretendardFont(.regular13)
                .foregroundStyle(.gray300)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
          }
          switch store.viewState {
          case .unavailable:
            Text("대댓글을 불러올 수 없어요.")
              .pretendardFont(.regular13)
              .foregroundStyle(.gray300)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(16)
          case .empty:
            Text("아직 대댓글이 없어요.")
              .pretendardFont(.regular13)
              .foregroundStyle(.gray300)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(16)
          case let .loaded(replies):
            ForEach(replies) { reply in
              replyCard(reply)
            }
          }
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
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
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}
