//
//  ClassBattlePreviewView.swift
//  Class
//
//  Created by Picke on 10/21/26.
//

import ComposableArchitecture
import HomeDomainInterface
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassBattlePreviewFeature.self)
public struct ClassBattlePreviewView: View {
  @Bindable public var store: StoreOf<ClassBattlePreviewFeature>

  public init(store: StoreOf<ClassBattlePreviewFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar
      previewBadge()
      conversation()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      playerBar
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onDisappear { send(.onDisappear) }
  }
}

private extension ClassBattlePreviewView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.title
    )
    .foregroundStyle(.textDefault)
  }

  /// Android `ClassBattlePreviewBadge`.
  @ViewBuilder
  func previewBadge() -> some View {
    HStack(spacing: 2) {
      Image(systemName: "play.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 9, height: 10)
        .frame(width: 16, height: 16)
      Text("1분 미리 듣기 중")
        .pretendardFont(.headingSmall)
    }
    .foregroundStyle(.textPrimary)
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
    .background(.surfacePrimarySubtle, in: Capsule())
    .padding(.top, 8)
  }

  @ViewBuilder
  func conversation() -> some View {
    switch store.viewState {
    case .loading:
      ProgressView()
        .tint(.primary500)

    case .error:
      PickeRetryErrorView(message: "대화를 불러오지 못했어요") {
        send(.retryTapped)
      }

    case .loaded:
      scriptList()
    }
  }

  /// Android `ClassBattlePreviewScriptSection` — 나온 대사만 `ScenarioChatBubble` 로 쌓고 재생 중인 대사로 스크롤한다.
  @ViewBuilder
  func scriptList() -> some View {
    let rows = store.visibleRows
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: Metric.rowSpacing) {
          ForEach(rows) { row in
            scriptRow(row)
              .padding(.top, row.hasTopSpacing ? Metric.speakerGroupSpacing : 0)
              .id(row.id)
          }

          if let error = store.audioErrorMessage {
            Text(error)
              .pretendardFont(.regular13)
              .foregroundStyle(.textPrimary)
              .frame(maxWidth: .infinity)
              .padding(.top, 20)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 40)
      }
      .scrollIndicators(.hidden)
      .onChange(of: store.scrollTargetRowID) { _, id in
        guard let id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(id, anchor: .top)
        }
      }
    }
  }

  /// Android `ScenarioChatBubble` — 재생 중인 대사만 진하게, 나머지는 흐리게 보인다.
  @ViewBuilder
  func scriptRow(_ row: ClassBattlePreviewRow) -> some View {
    let isActive = row.isActive
    switch row.speaker.side {
    case .center:
      Text(row.displayText)
        .pretendardFont(.labelSmall, lineSpacingMultiple: 1.4)
        .italic()
        .foregroundStyle(isActive ? .textSubtle : .textMuted)
        .multilineTextAlignment(.center)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .opacity(isActive ? 1 : Metric.dimmedOpacity)
    case .left, .right:
      chatBubble(row.script, speaker: row.speaker, showsHeader: row.showsHeader, isActive: isActive)
    }
  }

  @ViewBuilder
  func chatBubble(
    _ script: ScenarioScript,
    speaker: ChatSpeaker,
    showsHeader: Bool,
    isActive: Bool
  ) -> some View {
    let isLeft = speaker.side == .left
    HStack(alignment: .top, spacing: 6) {
      if isLeft {
        avatarSlot(speaker, isVisible: showsHeader)
      }
      VStack(alignment: isLeft ? .leading : .trailing, spacing: 6) {
        if showsHeader {
          Text(speaker.name)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.textDefault)
        }
        HStack(spacing: 6) {
          if !isLeft, isActive {
            AudioEqualizerView()
          }
          Text(script.text)
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
          if isLeft, isActive {
            AudioEqualizerView()
          }
        }
      }
      if !isLeft {
        avatarSlot(speaker, isVisible: showsHeader)
      }
    }
    .frame(maxWidth: .infinity, alignment: isLeft ? .leading : .trailing)
    .opacity(isActive ? 1 : Metric.dimmedOpacity)
  }

  /// Android `ChatBubbleAvatar` — 안 보일 때도 40 자리를 비워 둔다.
  @ViewBuilder
  func avatarSlot(
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

  /// Android `AudioPlayerBar` — 배속은 누를 때마다 1.0 → 1.5 → 2.0 → 3.0 으로 돈다.
  var playerBar: some View {
    PickeAudioPlayerBar(
      isPlaying: store.isPlaying,
      currentTime: store.currentTime,
      totalDuration: store.previewDuration,
      playbackRateTitle: store.playbackRateTitle,
      isSeekEnabled: store.isAudioReady,
      onTogglePlay: { send(.togglePlayTapped) },
      onSeek: { send(.scrubbed($0)) },
      onBackward: { send(.seekBackwardTapped) },
      onForward: { send(.seekForwardTapped) },
      onPlaybackRateTapped: { send(.playbackRateSelected(store.nextPlaybackRate)) },
      onReplay: { send(.replayTapped) }
    )
    .disabled(!store.isAudioReady)
  }
}

/// Android `ChatBubble` · `ClassBattlePreviewScreen` 치수.
private enum Metric {
  static let avatarSize: CGFloat = 40
  static let avatarImageSize: CGFloat = 28
  static let bubbleMaxWidth: CGFloat = 272
  static let rowSpacing: CGFloat = 6
  static let speakerGroupSpacing: CGFloat = 14
  static let dimmedOpacity: CGFloat = 0.8
}
