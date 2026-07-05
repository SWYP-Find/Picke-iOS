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

  private enum Metric {
    static let bubbleMaxWidth: CGFloat = 222
    static let avatarSize: CGFloat = 32.7
    static let avatarImageWidth: CGFloat = 24
    static let avatarImageHeight: CGFloat = 28
  }

  public init(store: StoreOf<ChatRoomFeature>) {
    self.store = store
  }

  public var body: some View {
    Group {
      if shouldShowSkeleton {
        ChatRoomSkeletonView()
      } else if shouldShowLoadError {
        scenarioErrorView()
      } else {
        VStack(spacing: 0) {
          navigationBar()
          messageList()
          if store.shouldShowOptions {
            interactiveOptionsSection()
          }
          playerBar()
        }
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .overlay(alignment: .top) {
      if store.hasAudioError {
        FloatingErrorView(message: "오디오를 불러오는 중 문제가 발생했어요")
          .padding(.top, 64)
          .transition(.move(edge: .top).combined(with: .opacity))
          .zIndex(1)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: store.hasAudioError)
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  private var shouldShowSkeleton: Bool {
    store.isLoadingScenario && store.scenario == nil
  }

  /// 시나리오 로드 실패 & 아직 로드된 시나리오가 없을 때 오류+재시도 노출.
  private var shouldShowLoadError: Bool {
    store.scenarioLoadFailed && store.scenario == nil
  }

  @ViewBuilder
  private func scenarioErrorView() -> some View {
    VStack(spacing: 0) {
      navigationBar()
      PickeRetryErrorView(message: "대화를 불러오지 못했어요") { send(.retryTapped) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .pretendardFont(.headingMedium)
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
    ScrollViewReader { proxy in
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 20) {
          ForEach(groupedMessages, id: \.id) { group in
            messageGroup(group)
              .transition(.opacity)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        // 대사가 한 줄씩 추가될 때 슬라이드/페이드인.
        .animation(.easeInOut(duration: 0.25), value: store.messages)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onChange(of: store.activeMessageId) { _, activeMessageId in
        guard let target = scrollTargetId(for: activeMessageId) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(target, anchor: .bottom)
        }
      }
    }
  }

  /// 활성 메시지가 속한 SpeakerGroup 의 마지막 메시지 id 로 스크롤한다.
  private func scrollTargetId(for activeId: UUID?) -> UUID? {
    guard let activeId else { return nil }
    for group in groupedMessages where group.messages.contains(where: { $0.id == activeId }) {
      return group.messages.last?.id ?? activeId
    }
    return activeId
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
            .id(message.id)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  @ViewBuilder
  private func avatar(_ speaker: ChatSpeaker) -> some View {
    KFImage(URL(string: speaker.imageURL ?? ""))
      .placeholder {
        SkeletonView(cornerRadius: Metric.avatarSize / 2)
      }
      .resizable()
      .scaledToFit()
      .frame(width: Metric.avatarImageWidth, height: Metric.avatarImageHeight)
      .frame(width: Metric.avatarSize, height: Metric.avatarSize)
      .background(.beige600, in: Circle())
  }

  @ViewBuilder
  private func bubbleColumn(
    speaker: ChatSpeaker,
    messages: [ChatMessage]
  ) -> some View {
    let alignment: HorizontalAlignment = speaker.side == .left ? .leading : .trailing
    VStack(alignment: alignment, spacing: 6) {
      Text(speaker.name)
        .pretendardFont(.semiBold13)
        .foregroundStyle(.neutral500)
        .padding(.horizontal, 4)

      // 오른쪽 화자는 말풍선도 우측 정렬되도록 내부 VStack 정렬을 side 에 맞춘다.
      VStack(alignment: alignment, spacing: 6) {
        ForEach(messages) { message in
          let isActive = store.isPlaying && message.id == store.activeMessageId
          HStack(alignment: .center, spacing: 6) {
            if speaker.side == .right, isActive { waveformIcon() }
            bubble(text: message.text, side: speaker.side, isActive: isActive)
              .id(message.id)
            if speaker.side == .left, isActive { waveformIcon() }
          }
          .transition(.opacity)
        }
      }
    }
    .frame(maxWidth: Metric.bubbleMaxWidth, alignment: speaker.side == .left ? .leading : .trailing)
  }

  @ViewBuilder
  private func bubble(
    text: String,
    side: ChatSpeakerSide,
    isActive: Bool = false
  ) -> some View {
    // 재생 중인 말풍선은 흰 배경으로 강조 (테두리는 동일 유지).
    let background: Color = isActive ? .beige50 : (side == .left ? .beige300 : .beige400)
    let border: Color = side == .left ? .beige600 : .beige700
    Text(text)
      .pretendardFont(.regular13)
      .foregroundStyle(isActive ? .neutral800 : .neutral500)
      .lineSpacing(13 * 0.4)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .roundedBackground(background)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(border, lineWidth: 1)
      )
  }

  /// 재생 중 말풍선 옆 이퀄라이저 애니메이션 (재생 상태에 반응).
  @ViewBuilder
  private func waveformIcon() -> some View {
    AudioEqualizerView(isPlaying: store.isPlaying)
      .frame(width: 24, height: 24)
  }

  /// 나레이션/클로징: 박스·테두리 없이 가운데 정렬 + 살짝 기울인 이탤릭.
  @ViewBuilder
  private func narratorBubble(text: String) -> some View {
    Text(text)
      .pretendardFont(.bodySmall)
      .italic()
      .foregroundStyle(.neutral400)
      .lineSpacing(12 * 0.4)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      .frame(maxWidth: 280)
  }

  private struct SpeakerGroup: Equatable, Identifiable {
    let speaker: ChatSpeaker
    var messages: [ChatMessage]

    var id: UUID { messages.first?.id ?? UUID() }
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
        .pretendardFont(.bold13)
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
      ForEach(store.visibleOptions, id: \.label) { option in
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
        .pretendardFont(.labelSmall)
        .foregroundStyle(isSelected ? .neutral800 : .neutral300)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .roundedBackground(.beige400)
        .overlay(
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(isSelected ? .borderSecondarySelected : .borderBeigeDefault, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func confirmButton() -> some View {
    Button("입장 선택하기") { send(.confirmOptionTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 42)
      .disabled(!store.isConfirmEnabled)
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
      }
      .frame(height: 16)

      HStack {
        Text(timeString(store.currentTime))
        Spacer()
        Text(timeString(store.totalDuration))
      }
      .pretendardFont(.medium11)
      .foregroundStyle(.neutral300)
    }
  }

  private func timeString(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}
