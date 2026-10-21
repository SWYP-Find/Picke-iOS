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
      previewBadge
      conversation()
      playerBar()
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
    .foregroundStyle(.neutral900)
  }

  var previewBadge: some View {
    Label("1분 미리 듣기 중", systemImage: "play.fill")
      .pretendardFont(.semiBold12)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 10)
      .frame(height: 25)
      .background(.beige500, in: Capsule())
      .frame(maxWidth: .infinity)
      .padding(.top, 4)
      .padding(.bottom, 20)
  }

  @ViewBuilder
  func conversation() -> some View {
    switch store.viewState {
    case .loading:
      ProgressView()
        .tint(.primary500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .error:
      PickeRetryErrorView(message: "대화를 불러오지 못했어요") {
        send(.retryTapped)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .loaded:
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 22) {
            ForEach(store.previewScripts) { script in
              scriptRow(script)
                .id(script.id)
            }

            if let error = store.audioErrorMessage {
              Text(error)
                .pretendardFont(.regular13)
                .foregroundStyle(.primary500)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 2)
          .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onChange(of: store.currentTime) { _, _ in
          let scripts = store.previewScripts.filter {
            TimeInterval($0.startTimeMs) / 1000 <= store.currentTime
          }
          if let last = scripts.last {
            withAnimation(.easeOut(duration: 0.2)) {
              proxy.scrollTo(last.id, anchor: .bottom)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  func scriptRow(_ script: ScenarioScript) -> some View {
    let speaker = store.withState { $0.speaker(for: script) }
    switch speaker.side {
    case .left:
      HStack(alignment: .top, spacing: 8) {
        avatar(speaker)
        scriptContent(script, speaker: speaker)
        Spacer(minLength: 0)
      }
    case .right:
      HStack(alignment: .top, spacing: 8) {
        Spacer(minLength: 0)
        scriptContent(script, speaker: speaker)
        avatar(speaker)
      }
    case .center:
      scriptContent(script, speaker: speaker)
        .frame(maxWidth: .infinity)
    }
  }

  func scriptContent(
    _ script: ScenarioScript,
    speaker: ChatSpeaker
  ) -> some View {
    VStack(alignment: speaker.side == .right ? .trailing : .leading, spacing: 6) {
      Text(speaker.name)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.neutral900)

      Text(script.text)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray400)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .pickeCard(
          speaker.side == .right ? .beige400 : .cardBaseBackgroundDefault,
          insideBorder: speaker.side == .right
        )
    }
    .frame(maxWidth: .infinity, alignment: speaker.side == .right ? .trailing : .leading)
  }

  func avatar(_ speaker: ChatSpeaker) -> some View {
    Group {
      switch speaker.name {
      case "플라톤":
        Image(asset: .avatarPlato)
          .resizable()
          .scaledToFit()
      case "사르트르":
        Image(asset: .avatarSartre)
          .resizable()
          .scaledToFit()
      default:
        PickeRemoteImage(
          url: speaker.imageURL ?? "",
          shape: .round(cornerRadius: 18)
        )
        .content(.fit)
      }
    }
    .frame(width: 36, height: 36)
    .background(.beige600, in: Circle())
  }

  @ViewBuilder
  func playerBar() -> some View {
    VStack(spacing: 12) {
      progressBar()
      AudioPlayerControlView(
        isPlaying: .constant(store.isPlaying),
        onBackward: { send(.seekBackwardTapped) },
        onTogglePlay: { send(.togglePlayTapped) },
        onForward: { send(.seekForwardTapped) },
        onReplay: { send(.replayTapped) },
        isReplayEnabled: store.isAudioReady,
        tint: .neutral900,
        playbackRateTitle: store.playbackRateTitle,
        onPlaybackRateSelected: { send(.playbackRateSelected($0)) }
      )
      .disabled(!store.isAudioReady)
    }
    .padding(.horizontal, 24)
    .padding(.top, 14)
    .padding(.bottom, 8)
    .background(.white)
  }

  @ViewBuilder
  func progressBar() -> some View {
    VStack(spacing: 2) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.neutral300)
            .frame(height: 3)
          Capsule()
            .fill(.primary500)
            .frame(width: geometry.size.width * store.progress, height: 3)
          Circle()
            .fill(.primary500)
            .frame(width: 10, height: 10)
            .offset(x: max(0, geometry.size.width * store.progress - 5))
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              guard store.isAudioReady, geometry.size.width > 0 else { return }
              let ratio = min(1, max(0, value.location.x / geometry.size.width))
              send(.scrubbed(store.previewDuration * ratio))
            }
        )
      }
      .frame(height: 12)

      HStack {
        Text(store.currentTimeText)
        Spacer()
        Text(store.durationText)
      }
      .pretendardFont(.medium11)
      .foregroundStyle(.neutral300)
    }
  }
}
