//
//  ChatRoomView.swift
//  Home
//
//  Created by Wonji Suh on 5/19/26.
//
//  .pen `채팅방` (k3lIx) + 와이어프레임 매핑 — 헤더 + 메시지 리스트 + 오디오 재생바.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: ChatRoomFeature.self)
public struct ChatRoomView: View {
  @Bindable public var store: StoreOf<ChatRoomFeature>

  public init(store: StoreOf<ChatRoomFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      messageList()
      playerBar()
    }
    .background(Color.beige200.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
  }
}

// MARK: - Navigation

extension ChatRoomView {
  @ViewBuilder
  private func navigationBar() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) }
    ) {
      Button { send(.refreshTapped) } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
    }
    .overlay(alignment: .center) {
      Text(store.battleTitle)
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.neutral800)
        .lineLimit(1)
        .padding(.horizontal, 56)
    }
    .foregroundStyle(.neutral800)
    .background(.beige50)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }
}

// MARK: - Messages

extension ChatRoomView {
  @ViewBuilder
  private func messageList() -> some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 20) {
        ForEach(groupedMessages, id: \.id) { group in
          messageGroup(group)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var groupedMessages: [SpeakerGroup] {
    var result: [SpeakerGroup] = []
    for message in store.messages {
      if let last = result.last, last.speaker == message.speaker {
        var updated = last
        updated.messages.append(message)
        result[result.count - 1] = updated
      } else {
        result.append(SpeakerGroup(speaker: message.speaker, messages: [message]))
      }
    }
    return result
  }

  @ViewBuilder
  private func messageGroup(_ group: SpeakerGroup) -> some View {
    HStack(alignment: .top, spacing: 8) {
      if group.speaker.side == .left {
        avatar(group.speaker)
        bubbleColumn(speaker: group.speaker, messages: group.messages)
        Spacer(minLength: 40)
      } else {
        Spacer(minLength: 40)
        bubbleColumn(speaker: group.speaker, messages: group.messages)
        avatar(group.speaker)
      }
    }
  }

  @ViewBuilder
  private func avatar(_ speaker: ChatSpeaker) -> some View {
    Image(asset: speaker.philosopher.imageAsset)
      .resizable()
      .scaledToFit()
      .frame(width: 16, height: 28)
      .frame(width: 40, height: 40)
      .background(.beige600, in: Circle())
  }

  @ViewBuilder
  private func bubbleColumn(speaker: ChatSpeaker, messages: [ChatMessage]) -> some View {
    VStack(alignment: speaker.side == .left ? .leading : .trailing, spacing: 6) {
      Text(speaker.philosopher.rawValue)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral800)
        .padding(.horizontal, 4)

      VStack(alignment: .leading, spacing: 6) {
        ForEach(messages) { message in
          bubble(text: message.text, side: speaker.side)
        }
      }
    }
  }

  @ViewBuilder
  private func bubble(text: String, side: ChatSpeakerSide) -> some View {
    Text(text)
      .pretendardFont(family: .Regular, size: 13)
      .foregroundStyle(.neutral400)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(
        side == .left ? Color.beige50 : Color.beige400,
        in: RoundedRectangle(cornerRadius: 2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(side == .left ? Color.beige600 : Color.beige700, lineWidth: 1)
      )
  }

  private struct SpeakerGroup: Equatable, Identifiable {
    let id = UUID()
    let speaker: ChatSpeaker
    var messages: [ChatMessage]
  }
}

// MARK: - Player Bar

extension ChatRoomView {
  @ViewBuilder
  private func playerBar() -> some View {
    VStack(spacing: 16) {
      progressBar()
      AudioPlayerControlView(
        isPlaying: .constant(store.isPlaying),
        onBackward: { send(.seekBackwardTapped) },
        onTogglePlay: { send(.togglePlayTapped) },
        onForward: { send(.seekForwardTapped) }
      )
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .background(.beige50)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }

  @ViewBuilder
  private func progressBar() -> some View {
    VStack(spacing: 8) {
      GeometryReader { proxy in
        let progress = store.totalDuration > 0
          ? CGFloat(store.currentTime / store.totalDuration)
          : 0
        ZStack(alignment: .leading) {
          Capsule().fill(.beige600).frame(height: 4)
          Capsule().fill(.primary500).frame(width: proxy.size.width * progress, height: 4)
          Circle()
            .fill(.primary500)
            .frame(width: 10, height: 10)
            .offset(x: max(0, proxy.size.width * progress - 5))
        }
      }
      .frame(height: 10)

      HStack {
        Text(timeString(store.currentTime))
        Spacer()
        Text(timeString(store.totalDuration))
      }
      .pretendardFont(family: .Medium, size: 11)
      .foregroundStyle(.neutral300)
    }
  }

  private func timeString(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}
