import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassAIChatFeature.self)
public struct ClassAIChatView: View {
  @Bindable public var store: StoreOf<ClassAIChatFeature>

  public init(store: StoreOf<ClassAIChatFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header
      conversation
      composer
    }
    .background(Color.beige50.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
  }
}

private extension ClassAIChatView {
  var header: some View {
    VStack(spacing: 12) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.battle.title)
        .foregroundStyle(.gray800)

      HStack(spacing: 16) {
        Text("ROUND \(min(store.round, 3)) · 입장에 반박해보세요")
          .pretendardFont(.semiBold11)
          .foregroundStyle(.gray300)
          .lineLimit(1)

        HStack(spacing: 5) {
          ForEach(1 ... 3, id: \.self) { step in
            Capsule()
              .fill(step <= store.round ? Color.primary500 : Color.beige600)
              .frame(width: 50, height: 4)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
    }
    .background(Color.beige50)
  }

  var conversation: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 6) {
          stanceNotice
            .padding(.bottom, 14)

          ForEach(store.messages.indices, id: \.self) { index in
            let message = store.messages[index]
            let beginsTurn = index == 0 || store.messages[index - 1].speaker != message.speaker
            messageRow(message, beginsTurn: beginsTurn)
              .id(message.id)
              .padding(.top, beginsTurn && index > 0 ? 14 : 0)
          }

          if store.isGenerating {
            HStack(spacing: 7) {
              ProgressView()
                .tint(.gray300)
              Text("\(store.opponentName)이(가) 답변을 생각하고 있어요")
                .pretendardFont(.regular13)
                .foregroundStyle(.gray300)
            }
            .padding(.leading, 46)
          }

          if let errorMessage = store.errorMessage {
            Text(errorMessage)
              .pretendardFont(.regular13)
              .foregroundStyle(.primary500)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12)
              .background(.white)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)
      .onChange(of: store.messages.count) { _, _ in
        if let lastMessage = store.messages.last {
          withAnimation { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
        }
      }
    }
  }

  var stanceNotice: some View {
    VStack(spacing: 2) {
      Text("사전투표에서 '\(store.selectedStanceTitle)'를 선택하셨네요.")
      Text("반대 입장의 \(store.opponentName)과 3라운드 토론을 시작해보세요.")
        .fontWeight(.semibold)
    }
    .pretendardFont(.regular11)
    .foregroundStyle(.gray700)
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .padding(.horizontal, 8)
    .background(Color.beige300)
  }

  func messageRow(_ message: ClassAIChatMessage, beginsTurn: Bool) -> some View {
    let isUser = message.speaker == .user
    return HStack(alignment: .top, spacing: 8) {
      if isUser {
        Spacer(minLength: 46)
      } else if beginsTurn {
        opponentAvatar
      } else {
        Color.clear.frame(width: 38, height: 1)
      }

      VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
        if beginsTurn {
          Text(isUser ? "나" : store.opponentName)
            .pretendardFont(.semiBold13)
            .foregroundStyle(.gray800)
        }

        Text(message.text)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray500)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 9)
          .padding(.vertical, 7)
          .background(isUser ? Color.beige300 : Color.white)
          .overlay(Rectangle().stroke(Color.beige600, lineWidth: 1))
      }

      if isUser, beginsTurn {
        userAvatar
      } else if isUser {
        Color.clear.frame(width: 38, height: 1)
      } else {
        Spacer(minLength: 46)
      }
    }
  }

  @ViewBuilder
  var opponentAvatar: some View {
    if let imageURL = store.opponentAvatarURL {
      AsyncImage(url: imageURL) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        avatarFallback(store.opponentName)
      }
      .frame(width: 38, height: 38)
      .clipShape(Circle())
    } else if let asset = opponentAvatarAsset {
      Image(asset: asset)
        .resizable()
        .scaledToFill()
        .frame(width: 38, height: 38)
        .clipShape(Circle())
    } else {
      avatarFallback(store.opponentName)
    }
  }

  var opponentAvatarAsset: ImageAsset? {
    switch store.opponentName {
    case "플라톤": .avatarPlato
    case "사르트르": .avatarSartre
    case "순자": .avatarSunja
    default: nil
    }
  }

  var userAvatar: some View {
    avatarFallback("나")
  }

  func avatarFallback(_ text: String) -> some View {
    Text(String(text.prefix(1)))
      .pretendardFont(.semiBold15)
      .foregroundStyle(.gray700)
      .frame(width: 38, height: 38)
      .background(Color.beige600, in: Circle())
  }

  var composer: some View {
    VStack(spacing: 10) {
      if store.isCompleted || !store.isModelAvailable {
        Button("최종투표하기") { send(.finalVoteTapped) }
          .ctaButtonStyle(.primary, size: .large, height: 52)
          .padding(.horizontal, 16)
      } else {
        if !store.quickReplies.isEmpty {
          ScrollView(.horizontal) {
            HStack(spacing: 8) {
              ForEach(store.quickReplies, id: \.self) { reply in
                Button(reply) { send(.quickReplyTapped(reply)) }
                  .pretendardFont(.regular11)
                  .foregroundStyle(.gray500)
                  .padding(.horizontal, 9)
                  .padding(.vertical, 7)
                  .background(Color.white, in: Capsule())
                  .overlay(Capsule().stroke(Color.beige600, lineWidth: 1))
                  .disabled(store.isGenerating)
              }
            }
            .padding(.horizontal, 16)
          }
          .scrollIndicators(.hidden)
        }

        HStack(spacing: 8) {
          TextField(
            "내 생각을 입력해보세요",
            text: Binding(
              get: { store.draft },
              set: { send(.draftChanged($0)) }
            ),
            axis: .vertical
          )
          .lineLimit(1 ... 3)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
          .padding(.horizontal, 9)
          .frame(minHeight: 44)
          .background(Color.white)
          .overlay(Rectangle().stroke(Color.beige600, lineWidth: 1))
          .disabled(store.isGenerating)

          Button { send(.sendTapped) } label: {
            Image(systemName: "paperplane")
              .font(.system(size: 19))
              .foregroundStyle(.white)
              .frame(width: 38, height: 38)
              .background(Color.primary500, in: Circle())
          }
          .buttonStyle(.plain)
          .disabled(store.isGenerating || store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .opacity(store.isGenerating || store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
          .accessibilityLabel("메시지 보내기")
        }
        .padding(.horizontal, 16)

        if store.errorMessage != nil {
          Button("최종투표로 이동하기") { send(.finalVoteTapped) }
            .pretendardFont(.regular13)
            .foregroundStyle(.gray500)
            .padding(.vertical, 6)
        }
      }
    }
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity)
    .background(Color.beige50)
    .overlay(alignment: .top) { Color.beige600.frame(height: 1) }
  }
}
