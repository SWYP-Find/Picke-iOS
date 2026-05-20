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
import Kingfisher

@ViewAction(for: ChatRoomFeature.self)
public struct ChatRoomView: View {
  @Bindable public var store: StoreOf<ChatRoomFeature>
  private static let bubbleMaxWidth: CGFloat = 222
  private static let avatarSize: CGFloat = 32.7
  private static let avatarImageWidth: CGFloat = 24
  private static let avatarImageHeight: CGFloat = 28

  public init(store: StoreOf<ChatRoomFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      messageList()
      if store.shouldShowOptions {
        interactiveOptionsSection()
      }
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
    switch group.speaker.side {
    case .left:
      HStack(alignment: .top, spacing: 8) {
        avatar(group.speaker)
        bubbleColumn(speaker: group.speaker, messages: group.messages)
        Spacer(minLength: 40)
      }

    case .right:
      HStack(alignment: .top, spacing: 8) {
        Spacer(minLength: 40)
        bubbleColumn(speaker: group.speaker, messages: group.messages)
        avatar(group.speaker)
      }

    case .center:
      VStack(spacing: 6) {
        ForEach(group.messages) { message in
          narratorBubble(text: message.text)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func avatar(_ speaker: ChatSpeaker) -> some View {
    KFImage(URL(string: speaker.imageURL ?? ""))
      .placeholder {
        SkeletonView(cornerRadius: Self.avatarSize / 2)
      }
      .resizable()
      .scaledToFit()
      .frame(width: Self.avatarImageWidth, height: Self.avatarImageHeight)
      .frame(width: Self.avatarSize, height: Self.avatarSize)
      .background(.beige600, in: Circle())
  }

  @ViewBuilder
  private func bubbleColumn(speaker: ChatSpeaker, messages: [ChatMessage]) -> some View {
    VStack(alignment: speaker.side == .left ? .leading : .trailing, spacing: 6) {
      Text(speaker.name)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral500)
        .padding(.horizontal, 4)

      VStack(alignment: .leading, spacing: 6) {
        ForEach(messages) { message in
          bubble(text: message.text, side: speaker.side)
        }
      }
    }
    .frame(maxWidth: Self.bubbleMaxWidth, alignment: speaker.side == .left ? .leading : .trailing)
  }

  @ViewBuilder
  private func bubble(text: String, side: ChatSpeakerSide) -> some View {
    Text(text)
      .pretendardFont(family: .Regular, size: 13)
      .foregroundStyle(.neutral500)
      .lineSpacing(13 * 0.4)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .frame(maxWidth: Self.bubbleMaxWidth, alignment: .leading)
      .background(
        side == .left ? Color.beige50 : Color.beige400,
        in: RoundedRectangle(cornerRadius: 2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(side == .left ? Color.beige600 : Color.beige700, lineWidth: 1)
      )
  }

  @ViewBuilder
  private func narratorBubble(text: String) -> some View {
    Text(text)
      .pretendardFont(family: .Regular, size: 12)
      .foregroundStyle(.neutral400)
      .lineSpacing(12 * 0.4)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(maxWidth: 280)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(.beige600, lineWidth: 1)
      )
  }

  private struct SpeakerGroup: Equatable, Identifiable {
    let id = UUID()
    let speaker: ChatSpeaker
    var messages: [ChatMessage]
  }
}

// MARK: - Interactive Options

extension ChatRoomView {
  @ViewBuilder
  private func interactiveOptionsSection() -> some View {
    VStack(spacing: 12) {
      optionsHeader()
      optionsList()
      confirmButton()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity)
    .background(.beige100)
  }

  @ViewBuilder
  private func optionsHeader() -> some View {
    HStack(spacing: 10) {
      Rectangle()
        .fill(.neutral200)
        .frame(height: 0.5)
      Text("당신의 입장을 선택해주세요")
        .pretendardFont(family: .Bold, size: 13)
        .foregroundStyle(.neutral800)
        .fixedSize()
      Rectangle()
        .fill(.neutral200)
        .frame(height: 0.5)
    }
  }

  @ViewBuilder
  private func optionsList() -> some View {
    VStack(spacing: 9) {
      ForEach(store.interactiveOptions, id: \.label) { option in
        optionCard(option)
      }
    }
  }

  @ViewBuilder
  private func optionCard(_ option: ScenarioInteractiveOption) -> some View {
    let isSelected = store.selectedOptionLabel == option.label

    Button {
      send(.optionTapped(option.label))
    } label: {
      Text(option.label)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(isSelected ? .neutral800 : .neutral300)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
        .overlay(
          RoundedRectangle(cornerRadius: 2)
            .stroke(isSelected ? .borderSecondarySelected : .borderBeigeDefault, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func confirmButton() -> some View {
    CustomButton(
      action: { send(.confirmOptionTapped) },
      title: "입장 선택하기",
      config: CustomButtonConfig.primary(.large, height: 42),
      isEnable: store.isConfirmEnabled
    )
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
            .frame(width: 16, height: 16)
            .offset(x: max(0, proxy.size.width * progress - 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              guard store.canScrub,
                    proxy.size.width > 0,
                    store.totalDuration > 0 else { return }
              let ratio = min(max(value.location.x / proxy.size.width, 0), 1)
              send(.scrub(store.totalDuration * Double(ratio)))
            }
        )
        .allowsHitTesting(store.canScrub)
        .opacity(store.canScrub ? 1.0 : 0.6)
      }
      .frame(height: 16)

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
