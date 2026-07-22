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
import Entity
import HomeDomainInterface
import Kingfisher
import PickeDesignKit

@ViewAction(for: ChatRoomFeature.self)
public struct ChatRoomView: View {
  @Bindable public var store: StoreOf<ChatRoomFeature>

  // [고정 36 슬롯][8][말풍선 고정폭][8][고정 36 슬롯] — 재생 상태와 무관하게 말풍선 크기 고정.
  private enum Metric {
    static let sideSlotWidth: CGFloat = 36
    static let avatarSize: CGFloat = 32
    static let avatarImageWidth: CGFloat = 24
    static let avatarImageHeight: CGFloat = 28
    static let bubblePadding: CGFloat = 12
    // 답답해 보이지 않도록 버블 간 간격을 넉넉하게.
    static let rowSpacing: CGFloat = 10
    static let speakerChangeSpacing: CGFloat = 24
    static let bodyLineSpacing: CGFloat = 4.8
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
        let rows = messageRows
        let insertAfter = selectionInsertAfterIndex(rows)
        VStack(alignment: .leading, spacing: Metric.rowSpacing) {
          if insertAfter == -1 {
            selectionHistorySection()
          }
          ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
            messageRow(row)
              .padding(.top, index > 0 && row.showsHeader ? Metric.speakerChangeSpacing : 0)
              .transition(.opacity)
            // 중간(분기) 선택 확정 내역 — 선택 지점 뒤에 유지 노출. (안드로이드 파리티)
            if index == insertAfter {
              selectionHistorySection()
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 40)
        // 대사가 한 줄씩 추가될 때 슬라이드/페이드인.
        .animation(.easeInOut(duration: 0.25), value: store.messages)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onChange(of: store.activeMessageId) { _, activeMessageId in
        guard let activeMessageId else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
          proxy.scrollTo(activeMessageId, anchor: .bottom)
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

  @ViewBuilder
  private func selectionHistorySection() -> some View {
    if let selection = store.confirmedSelection {
      VStack(spacing: 24) {
        HStack(spacing: 16) {
          Rectangle()
            .fill(.gray200)
            .frame(height: 1)
          Text("아래가 당신의 선택입니다.")
            .pretendardFont(.labelMedium)
            .italic()
            .foregroundStyle(.gray500)
            .fixedSize()
          Rectangle()
            .fill(.gray200)
            .frame(height: 1)
        }

        VStack(spacing: 12) {
          ForEach(selection.options, id: \.label) { option in
            historyOptionCard(option, isChosen: option.nextNodeId == selection.selectedNodeId)
          }
        }
      }
      .padding(.vertical, 16)
    }
  }

  @ViewBuilder
  private func historyOptionCard(_ option: ScenarioInteractiveOption, isChosen: Bool) -> some View {
    Text(option.label)
      .pretendardFont(.labelSmall)
      .foregroundStyle(isChosen ? .gray900 : .gray500)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, alignment: .center)
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .roundedBackground(.beige400)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(isChosen ? .secondary500 : .beige700, lineWidth: 1)
      )
  }

  private var messageRows: [MessageRow] {
    var rows: [MessageRow] = []
    for message in store.messages {
      let showsHeader = rows.last.map { $0.message.speaker != message.speaker } ?? true
      rows.append(MessageRow(message: message, showsHeader: showsHeader))
    }
    return rows
  }

  @ViewBuilder
  private func messageRow(_ row: MessageRow) -> some View {
    let message = row.message
    let speaker = message.speaker
    let isActive = message.id == store.activeMessageId

    switch speaker.side {
    case .center:
      narratorBubble(text: message.text, isActive: isActive)
        .opacity(isActive ? 1 : 0.8)
        .id(message.id)

    case .left, .right:
      HStack(alignment: .top, spacing: 8) {
        sideSlot(
          showsAvatar: speaker.side == .left && row.showsHeader,
          showsEqualizer: speaker.side == .right && isActive && store.isPlaying,
          speaker: speaker
        )

        VStack(alignment: speaker.side == .left ? .leading : .trailing, spacing: 6) {
          if row.showsHeader {
            Text(speaker.name)
              .pretendardFont(.headingSmall)
              .foregroundStyle(.gray400)
          }
          bubble(text: message.text, side: speaker.side, isActive: isActive)
        }
        .frame(maxWidth: .infinity)

        sideSlot(
          showsAvatar: speaker.side == .right && row.showsHeader,
          showsEqualizer: speaker.side == .left && isActive && store.isPlaying,
          speaker: speaker
        )
      }
      .opacity(isActive ? 1 : 0.8)
      .id(message.id)
    }
  }

  @ViewBuilder
  private func sideSlot(
    showsAvatar: Bool,
    showsEqualizer: Bool,
    speaker: ChatSpeaker
  ) -> some View {
    ZStack {
      if showsAvatar {
        avatar(speaker)
      } else if showsEqualizer {
        waveformIcon()
      }
    }
    .frame(width: Metric.sideSlotWidth)
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
  private func waveformIcon() -> some View {
    AudioEqualizerView(isPlaying: store.isPlaying)
      .frame(width: 24, height: 24)
  }

  @ViewBuilder
  private func bubble(
    text: String,
    side: ChatSpeakerSide,
    isActive: Bool
  ) -> some View {
    let background: Color = side == .left ? .white : .beige500
    let border: Color = side == .left ? .beige500 : .beige700
    Text(text)
      .pretendardFont(.labelSmall)
      .foregroundStyle(isActive ? .gray700 : .gray300)
      .lineSpacing(Metric.bodyLineSpacing)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Metric.bubblePadding)
      .roundedBackground(background)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(border, lineWidth: 1)
      )
  }

  @ViewBuilder
  private func narratorBubble(text: String, isActive: Bool) -> some View {
    Text(text.replacingOccurrences(of: ", ", with: ",\n"))
      .pretendardFont(.labelSmall)
      .italic()
      .foregroundStyle(isActive ? .gray700 : .gray300)
      .lineSpacing(Metric.bodyLineSpacing)
      .multilineTextAlignment(.center)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
  }

  private struct MessageRow: Equatable, Identifiable {
    let message: ChatMessage
    let showsHeader: Bool

    var id: UUID { message.id }
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
    .background(.beige200)
  }

  @ViewBuilder
  private func optionsHeader() -> some View {
    HStack(spacing: 16) {
      Rectangle()
        .fill(.gray200)
        .frame(height: 1)
      Text("이제 당신의 입장을 선택해주세요")
        .pretendardFont(.labelMedium)
        .italic()
        .foregroundStyle(.gray500)
        .fixedSize()
      Rectangle()
        .fill(.gray200)
        .frame(height: 1)
    }
  }

  @ViewBuilder
  private func optionsList() -> some View {
    VStack(spacing: 12) {
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
        .foregroundStyle(isSelected ? .gray900 : .gray500)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .roundedBackground(.beige400)
        .overlay(
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(isSelected ? .secondary500 : .beige700, lineWidth: 1)
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
        onForward: { send(.seekForwardTapped) },
        // 안드로이드 시안: 재생 컨트롤 아이콘은 브라운(primary500).
        tint: .primary500
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
