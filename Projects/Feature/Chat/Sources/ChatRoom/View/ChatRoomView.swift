//
//  ChatRoomView.swift
//  Chat
//
//  Created by Picke on 5/19/26.
//

import ComposableArchitecture
import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ChatRoomFeature.self)
public struct ChatRoomView: View {
  @Bindable public var store: StoreOf<ChatRoomFeature>

  /// Android `ChatBubble` · `ScenarioScreen` 치수.
  private enum Metric {
    static let avatarSize: CGFloat = 40
    /// `ProfileImageKind.PHILOSOPHER` — 안쪽 이미지 40 × 28/40.
    static let avatarImageSize: CGFloat = 28
    static let bubbleMaxWidth: CGFloat = 272
    static let rowSpacing: CGFloat = 6
    static let speakerGroupSpacing: CGFloat = 14
    static let dimmedOpacity: CGFloat = 0.8
  }

  private static let optionsAnchorID = "scenarioOptions"

  public init(store: StoreOf<ChatRoomFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
          if store.hasAudioError {
            FloatingErrorView(message: "오디오를 불러오는 중 문제가 발생했어요")
              .padding(.top, 16)
              .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
      playerBar
    }
    .screenBackground()
    .animation(.easeInOut(duration: 0.25), value: store.hasAudioError)
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  @ViewBuilder
  private var content: some View {
    if store.isLoadingScenario, store.scenario == nil {
      ChatRoomSkeletonView()
    } else {
      messageList()
    }
  }
}

// MARK: - Navigation

extension ChatRoomView {
  @ViewBuilder
  private func navigationBar() -> some View {
    // Android `PickeTopAppBar` — 가운데 제목만, 배경 `backgroundBeige`, 구분선 없음.
    // Android 는 시스템 뒤로 가기를 쓰지만 iOS 는 시스템 버튼이 없어 뒤로 버튼은 남긴다.
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: store.battleTitle
    )
    .foregroundStyle(.textDefault)
  }
}

// MARK: - Messages

extension ChatRoomView {
  @ViewBuilder
  private func messageList() -> some View {
    ScrollViewReader { proxy in
      ScrollView(showsIndicators: false) {
        let rows = messageRows
        let insertAfter = selectionInsertAfterIndex(rows)
        VStack(alignment: .leading, spacing: Metric.rowSpacing) {
          if insertAfter == -1 {
            selectionHistorySection()
          }
          ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
            // Android `isNewSpeaker || isNewNode` — 화자가 바뀌거나 선택 지점 바로 뒤면 이름·아바타를 다시 보인다.
            let showsHeader = row.showsHeader || index == (insertAfter ?? -2) + 1
            messageRow(
              row.message,
              showsHeader: showsHeader
            )
            .padding(.top, index > 0 && showsHeader ? Metric.speakerGroupSpacing : 0)
            .transition(.opacity)
            if index == insertAfter {
              selectionHistorySection()
            }
          }
          if store.shouldShowOptions {
            interactiveOptionsSection()
              .id(Self.optionsAnchorID)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .animation(.easeInOut(duration: 0.25), value: store.messages)
      }
      .onChange(of: store.activeMessageId) { _, activeMessageId in
        guard let activeMessageId, !store.shouldShowOptions else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(activeMessageId, anchor: .top)
        }
      }
      .onChange(of: store.shouldShowOptions) { _, isShown in
        guard isShown else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(Self.optionsAnchorID, anchor: .bottom)
        }
      }
    }
  }

  /// 확정 선택 내역 블록을 끼워 넣을 행 인덱스(해당 행 뒤에 삽입). -1 이면 맨 앞, nil 이면 미노출.
  private func selectionInsertAfterIndex(_ rows: [MessageRow]) -> Int? {
    guard let startMs = store.confirmedSelectionStartMs else { return nil }
    let firstAfter = rows.firstIndex { ($0.message.startTimeMs ?? 0) >= startMs } ?? rows.count
    return firstAfter - 1
  }

  private var messageRows: [MessageRow] {
    var rows: [MessageRow] = []
    for message in store.messages {
      let showsHeader = rows.last.map { $0.message.speaker != message.speaker } ?? true
      rows.append(MessageRow(message: message, showsHeader: showsHeader))
    }
    return rows
  }

  /// Android `ScenarioChatBubble` — 재생 중인 대사만 활성. 멈추면 모든 대사가 흐려진다.
  @ViewBuilder
  private func messageRow(
    _ message: ChatMessage,
    showsHeader: Bool
  ) -> some View {
    let isActive = store.isPlaying && message.id == store.activeMessageId
    switch message.speaker.side {
    case .center:
      narratorBubble(
        text: message.text,
        isActive: isActive
      )
      .id(message.id)
    case .left, .right:
      chatBubble(
        message,
        showsHeader: showsHeader,
        isActive: isActive
      )
      .id(message.id)
    }
  }

  @ViewBuilder
  private func chatBubble(
    _ message: ChatMessage,
    showsHeader: Bool,
    isActive: Bool
  ) -> some View {
    let isLeft = message.speaker.side == .left
    HStack(alignment: .top, spacing: 6) {
      if isLeft {
        avatarSlot(message.speaker, isVisible: showsHeader)
      }
      VStack(alignment: isLeft ? .leading : .trailing, spacing: 6) {
        if showsHeader {
          Text(message.speaker.name)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.textDefault)
        }
        HStack(spacing: 6) {
          if !isLeft, isActive {
            AudioEqualizerView()
          }
          bubble(
            text: message.text,
            isLeft: isLeft
          )
          if isLeft, isActive {
            AudioEqualizerView()
          }
        }
      }
      if !isLeft {
        avatarSlot(message.speaker, isVisible: showsHeader)
      }
    }
    .frame(maxWidth: .infinity, alignment: isLeft ? .leading : .trailing)
    .opacity(isActive ? 1 : Metric.dimmedOpacity)
  }

  /// Android `ChatBubbleAvatar` — 안 보일 때도 40 자리를 비워 둔다.
  @ViewBuilder
  private func avatarSlot(
    _ speaker: ChatSpeaker,
    isVisible: Bool
  ) -> some View {
    if isVisible {
      Circle()
        .fill(.borderBeigeDefault)
        .overlay {
          PickeRemoteImage(url: speaker.imageURL) {
            Color.clear
          }
          .content(.fit)
          .frame(width: Metric.avatarImageSize, height: Metric.avatarImageSize)
        }
        .frame(width: Metric.avatarSize, height: Metric.avatarSize)
    } else {
      Color.clear
        .frame(width: Metric.avatarSize, height: Metric.avatarSize)
    }
  }

  /// 말풍선 폭은 최대 272 까지 채운다(Android `widthIn(max = 272).fillMaxWidth()`).
  @ViewBuilder
  private func bubble(
    text: String,
    isLeft: Bool
  ) -> some View {
    Text(text)
      .pretendardFont(.regular13, lineSpacingMultiple: 1.4)
      .foregroundStyle(.textBody)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)
      .padding(.vertical, isLeft ? 6 : 8)
      .pickeCard(
        isLeft ? .surfaceBeigeDefault : .surfaceBeigeStrong,
        border: .borderBeigeDefault
      )
      .frame(maxWidth: Metric.bubbleMaxWidth)
  }

  @ViewBuilder
  private func narratorBubble(
    text: String,
    isActive: Bool
  ) -> some View {
    Text(text.replacingOccurrences(of: ", ", with: ",\n"))
      .pretendardFont(.labelSmall, lineSpacingMultiple: 1.4)
      .italic()
      .foregroundStyle(isActive ? .textSubtle : .textMuted)
      .multilineTextAlignment(.center)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .opacity(isActive ? 1 : Metric.dimmedOpacity)
  }

  private struct MessageRow: Equatable, Identifiable {
    let message: ChatMessage
    let showsHeader: Bool

    var id: UUID {
      message.id
    }
  }
}

// MARK: - Interactive Options

extension ChatRoomView {
  /// Android `InteractiveOptionsUI`(확정 전) — 리스트 맨 끝에 안내선 + 카드 + "입장 선택하기".
  @ViewBuilder
  private func interactiveOptionsSection() -> some View {
    VStack(spacing: 0) {
      optionsGuide("이제 당신의 입장을 선택해주세요")
      VStack(spacing: 12) {
        ForEach(store.visibleOptions, id: \.label) { option in
          Button {
            send(.optionTapped(option.label))
          } label: {
            optionCard(
              option.label,
              isSelected: store.selectedOptionLabel == option.label
            )
          }
          .buttonStyle(.plain)
        }
        confirmButton
      }
      .padding(.top, 24)
    }
    .padding(.top, 32)
    .padding(.bottom, 16)
  }

  /// Android `InteractiveOptionsUI`(확정 후) — 같은 모양, 카드는 누를 수 없고 확인 버튼이 없다.
  @ViewBuilder
  private func selectionHistorySection() -> some View {
    if let selection = store.confirmedSelection {
      VStack(spacing: 0) {
        optionsGuide("아래가 당신의 선택입니다.")
        VStack(spacing: 12) {
          ForEach(selection.options, id: \.label) { option in
            optionCard(
              option.label,
              isSelected: option.nextNodeId == selection.selectedNodeId
            )
          }
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
      }
      .padding(.top, 32)
      .padding(.bottom, 16)
    }
  }

  @ViewBuilder
  private func optionsGuide(_ text: String) -> some View {
    HStack(spacing: 0) {
      PickeDivider(.gray200)
      Text(text)
        .pretendardFont(.labelMedium)
        .italic()
        .foregroundStyle(.textSubtler)
        .fixedSize()
        .padding(.horizontal, 16)
      PickeDivider(.gray200)
    }
  }

  /// Android `OptionSelectionCard` — `surfaceBeigeStrong` 면, 테두리 선택 `secondary500` / 그 외 `borderBeigeSelected`.
  private func optionCard(
    _ label: String,
    isSelected: Bool
  ) -> some View {
    Text(label)
      .pretendardFont(.labelSmall)
      .foregroundStyle(isSelected ? .textDefault : .textSubtler)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .pickeCard(
        .surfaceBeigeStrong,
        border: isSelected ? .secondary500 : .borderBeigeSelected
      )
      .contentShape(Rectangle())
  }

  /// Android `OptionConfirmButton` — radius 2, 세로 16, 12 Medium.
  private var confirmButton: some View {
    Button {
      send(.confirmOptionTapped)
    } label: {
      Text("입장 선택하기")
        .pretendardFont(.labelSmall)
        .foregroundStyle(.buttonPrimaryTextDefault)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .roundedBackground(
          store.isConfirmEnabled ? .buttonPrimaryBackgroundDefault : .buttonPrimaryBackgroundDisabled,
          radius: .radiusDefault
        )
    }
    .buttonStyle(.plain)
    .disabled(!store.isConfirmEnabled)
  }
}

// MARK: - Player Bar

extension ChatRoomView {
  private var playerBar: some View {
    PickeAudioPlayerBar(
      isPlaying: store.isPlaying,
      currentTime: store.currentTime,
      totalDuration: store.totalDuration,
      playbackRateTitle: store.playbackRateTitle,
      isSeekEnabled: store.canScrub,
      onTogglePlay: { send(.togglePlayTapped) },
      onSeek: { send(.scrub($0)) },
      onBackward: { send(.seekBackwardTapped) },
      onForward: { send(.seekForwardTapped) },
      onPlaybackRateTapped: { send(.playbackRateSelected(store.nextPlaybackRate)) },
      onReplay: { send(.replayTapped) }
    )
  }
}

#if DEBUG
  #Preview("채팅방 · 청취 중") {
    let scenario = BattleScenario(
      battleId: 0,
      title: "뒤샹의 변기, 예술인가 도발인가",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [:],
      nodes: [
        ScenarioNode(
          nodeId: 1,
          nodeName: "START",
          audioDuration: 268,
          autoNextNodeId: nil,
          scripts: [
            ScenarioScript(
              scriptId: 1,
              startTimeMs: 0,
              speakerType: .a,
              speakerName: "플라톤",
              text: "이건 기만입니다. 하늘 아래 모든 사물은 그에 걸맞은 완벽한 목적과 형상을 가지고 있습니다."
            ),
            ScenarioScript(
              scriptId: 2,
              startTimeMs: 9000,
              speakerType: .a,
              speakerName: "플라톤",
              text: "변기의 이데아는 감상하는 것이 아닙니다."
            ),
            ScenarioScript(
              scriptId: 3,
              startTimeMs: 18000,
              speakerType: .b,
              speakerName: "사르트르",
              text: "사물은 그저 그곳에 존재할 뿐입니다."
            ),
          ],
          interactiveOptions: []
        ),
      ]
    )
    let state: ChatRoomFeature.State = {
      var state = ChatRoomFeature.State()
      state.scenario = scenario
      state.currentNodeId = scenario.startNodeId
      state.visibleNodeIds = [scenario.startNodeId]
      state.currentTime = 24
      state.isPlaying = true
      return state
    }()
    ChatRoomView(store: Store(initialState: state) { ChatRoomFeature() })
  }
#endif
