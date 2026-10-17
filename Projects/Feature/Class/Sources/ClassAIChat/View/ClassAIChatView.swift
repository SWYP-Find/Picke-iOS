//
//  ClassAIChatView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassAIChatFeature.self)
public struct ClassAIChatView: View {
  @Bindable public var store: StoreOf<ClassAIChatFeature>
  @FocusState private var isInputFocused: Bool
  /// 보낼 때 입력창에 포커스가 있었으면 응답이 끝난 뒤 다시 포커스를 준다.
  @State private var refocusesAfterReply = false

  public init(store: StoreOf<ClassAIChatFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header()
      conversation()
      composer()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
    .onChange(of: store.isGenerating) { _, isGenerating in
      restoreFocusIfNeeded(isGenerating: isGenerating)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
  }
}

private extension ClassAIChatView {
  static let bottomAnchorID = "conversation-bottom"

  // MARK: - Header

  @ViewBuilder
  func header() -> some View {
    VStack(spacing: 6) {
      navigationBar
      roundProgress()
    }
    .padding(.bottom, 12)
  }

  /// `ClassCommentView` 처럼 제목을 덧씌우되, 피그마대로 뒤로가기 오른쪽에 왼쪽 정렬한다.
  /// 긴 배틀 제목은 뒤로가기 영역(16 + 24 + 16)을 피해 한 줄로 말줄임한다.
  var navigationBar: some View {
    PickeNavigationBar(onBack: { send(.backTapped) })
      .overlay {
        Text(store.room.battle.title)
          .pretendardFont(.headingMedium)
          .foregroundStyle(.gray500)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.leading, 56)
          .padding(.trailing, 16)
          .allowsHitTesting(false)
      }
      .foregroundStyle(.gray900)
  }

  @ViewBuilder
  func roundProgress() -> some View {
    HStack(spacing: 10) {
      Text(store.roundTitle)
        .pretendardFont(family: .Bold, size: 12)
        .foregroundStyle(.gray300)
        .lineLimit(1)
      Spacer(minLength: 0)
      roundBars()
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func roundBars() -> some View {
    HStack(spacing: 5) {
      ForEach(1 ... store.totalRounds, id: \.self) { step in
        Capsule()
          .fill(step <= store.round ? .primary500 : .beige600)
          .frame(width: 50, height: 4)
      }
    }
  }

  // MARK: - Conversation

  @ViewBuilder
  func conversation() -> some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 6) {
          stanceNotice
            .padding(.bottom, 14)

          ForEach(Array(store.messages.enumerated()), id: \.element.id) { index, message in
            let beginsTurn = index == 0 || store.messages[index - 1].speaker != message.speaker
            messageRow(message, beginsTurn: beginsTurn)
              .padding(.top, beginsTurn && index > 0 ? 14 : 0)
          }

          if store.isGenerating {
            thinkingIndicator()
          }

          if let errorMessage = store.errorMessage {
            errorBox(errorMessage)
          }

          Color.clear
            .frame(height: 1)
            .id(Self.bottomAnchorID)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)
      .onChange(of: store.messages.count) { _, _ in scrollToBottom(proxy) }
      .onChange(of: store.isGenerating) { _, _ in scrollToBottom(proxy) }
      .onChange(of: store.errorMessage) { _, _ in scrollToBottom(proxy) }
    }
  }

  var stanceNotice: some View {
    Text(stanceNoticeText)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .roundedBackground(.beige500)
  }

  var stanceNoticeText: AttributedString {
    store.stanceNoticeSegments.reduce(into: AttributedString()) { text, segment in
      var run = AttributedString(segment.text)
      run.font = .pretendardFontFamily(family: segment.isHighlighted ? .Bold : .Medium, size: 11)
      run.foregroundColor = segment.isHighlighted ? .gray800 : .gray400
      text += run
    }
  }

  @ViewBuilder
  func messageRow(
    _ message: ClassAIChatMessage,
    beginsTurn: Bool
  ) -> some View {
    if message.speaker == .user {
      userRow(message.text, beginsTurn: beginsTurn)
    } else {
      opponentRow(message.text, beginsTurn: beginsTurn)
    }
  }

  @ViewBuilder
  func opponentRow(
    _ text: String,
    beginsTurn: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: 6) {
      if beginsTurn {
        opponentAvatar
      } else {
        Color.clear.frame(width: 40, height: 1)
      }

      VStack(alignment: .leading, spacing: 6) {
        if beginsTurn {
          opponentName()
        }
        bubble(text, isUser: false)
      }
      .frame(maxWidth: 272, alignment: .leading)

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  func userRow(
    _ text: String,
    beginsTurn: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: 6) {
      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 6) {
        if beginsTurn {
          Text("나")
            .pretendardFont(.headingSmall)
            .foregroundStyle(.gray800)
        }
        bubble(text, isUser: true)
      }
      .frame(maxWidth: 272, alignment: .trailing)

      if beginsTurn {
        userAvatar
      } else {
        Color.clear.frame(width: 40, height: 1)
      }
    }
  }

  @ViewBuilder
  func opponentName() -> some View {
    HStack(spacing: 4) {
      Text(store.opponentName)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.gray800)
      Text("AI")
        .pretendardFont(.semiBold12)
        .foregroundStyle(.primary500)
        .padding(.horizontal, 4)
        .frame(height: 20)
        .background(.primary50, in: RoundedRectangle(cornerRadius: 2))
    }
  }

  func bubble(
    _ text: String,
    isUser: Bool
  ) -> some View {
    Text(text)
      .pretendardFont(.regular13)
      .foregroundStyle(.gray400)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)
      .padding(.vertical, isUser ? 8 : 6)
      .pickeCard(isUser ? .beige400 : .cardBaseBackgroundDefault)
  }

  @ViewBuilder
  func thinkingIndicator() -> some View {
    HStack(spacing: 7) {
      ProgressView()
        .tint(.gray300)
      Text(store.thinkingText)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    .padding(.leading, 46)
  }

  func errorBox(_ message: String) -> some View {
    Text(message)
      .pretendardFont(.regular13)
      .foregroundStyle(.primary500)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(.white)
  }

  // MARK: - Avatar

  @ViewBuilder
  var opponentAvatar: some View {
    if let asset = opponentAvatarAsset, store.opponentAvatarURL == nil {
      Image(asset: asset)
        .resizable()
        .scaledToFill()
        .pickeAvatar(size: 40)
    } else {
      PickeAvatarView(
        imageURL: store.opponentAvatarURL?.absoluteString,
        fallback: store.opponentName,
        size: 40
      )
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
    PickeAvatarView(
      imageURL: nil,
      fallback: "나",
      size: 40
    )
  }

  // MARK: - Composer

  @ViewBuilder
  func composer() -> some View {
    VStack(spacing: 12) {
      if store.isCompleted || !store.isModelAvailable {
        sessionEndActions()
      } else {
        inputRow()

        if store.errorMessage != nil {
          finalVoteLink
        }
      }
    }
    .padding(.top, 16)
    .padding(.bottom, 6)
    .frame(maxWidth: .infinity)
    .background(.beige600, ignoresSafeAreaEdges: .bottom)
    .topDivider(.beige700)
  }

  @ViewBuilder
  func sessionEndActions() -> some View {
    if store.canRetrySession {
      Button("AI 토론 다시 시도하기") { send(.retryTapped) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .padding(.horizontal, 16)
    }
    Button("최종투표하기") { send(.finalVoteTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .padding(.horizontal, 16)
  }

  @ViewBuilder
  func inputRow() -> some View {
    HStack(spacing: 8) {
      inputField
      sendButton
    }
    .padding(.horizontal, 16)
  }

  var inputField: some View {
    TextField(
      "내용을 입력하세요",
      text: Binding(
        get: { store.draft },
        set: { send(.draftChanged($0)) }
      ),
      prompt: Text("내용을 입력하세요").foregroundStyle(.gray300),
      axis: .vertical
    )
    .pretendardFont(.regular13)
    .foregroundStyle(.gray800)
    .lineLimit(1 ... 2)
    .focused($isInputFocused)
    .padding(.horizontal, 12)
    .frame(height: 52)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige50, border: .beige600)
    .disabled(store.isGenerating)
  }

  var sendButton: some View {
    Button {
      refocusesAfterReply = isInputFocused
      send(.sendTapped)
    } label: {
      Image(systemName: "paperplane")
        .pretendardFont(family: .Medium, size: 22)
        .foregroundStyle(.iconGrayInverse)
        .frame(width: 24, height: 24)
        .frame(width: 40, height: 40)
        .background(
          store.canSend ? .buttonIconBackgroundDefault : .buttonIconBackgroundDisabled,
          in: Circle()
        )
    }
    .buttonStyle(ClassAIChatSendButtonStyle())
    .disabled(!store.canSend)
    .accessibilityLabel("메시지 보내기")
  }

  var finalVoteLink: some View {
    Button("최종투표로 이동하기") { send(.finalVoteTapped) }
      .pretendardFont(.regular13)
      .foregroundStyle(.gray500)
      .padding(.vertical, 6)
  }

  // MARK: - Helpers

  func scrollToBottom(_ proxy: ScrollViewProxy) {
    withAnimation { proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom) }
  }

  func restoreFocusIfNeeded(isGenerating: Bool) {
    guard !isGenerating, refocusesAfterReply else { return }
    refocusesAfterReply = false
    guard !store.isCompleted else { return }
    isInputFocused = true
  }
}

/// 비활성 색상은 버튼 토큰이 담당하므로 기본 스타일의 추가 흐림을 적용하지 않는다.
private struct ClassAIChatSendButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.8 : 1)
  }
}
