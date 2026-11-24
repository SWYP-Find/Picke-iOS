//
//  AudioPlayerControlView.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

public struct AudioPlayerControlView: View {
  @Binding private var isPlaying: Bool
  private let onBackward: () -> Void
  private let onTogglePlay: () -> Void
  private let onForward: () -> Void
  private let onReplay: () -> Void
  /// 다시듣기 활성 여부. 끝까지 들은 적이 있을 때만 true.
  private let isReplayEnabled: Bool
  /// 화면에서 사용하는 오디오 컨트롤 색상.
  private let tint: Color
  private let playbackRateTitle: String
  private let captionVerticalOffset: CGFloat
  private let onPlaybackRateSelected: (Float) -> Void

  public init(
    isPlaying: Binding<Bool>,
    onBackward: @escaping () -> Void,
    onTogglePlay: @escaping () -> Void,
    onForward: @escaping () -> Void,
    onReplay: @escaping () -> Void,
    isReplayEnabled: Bool,
    tint: Color,
    playbackRateTitle: String,
    captionVerticalOffset: CGFloat = 0,
    onPlaybackRateSelected: @escaping (Float) -> Void
  ) {
    _isPlaying = isPlaying
    self.onBackward = onBackward
    self.onTogglePlay = onTogglePlay
    self.onForward = onForward
    self.onReplay = onReplay
    self.isReplayEnabled = isReplayEnabled
    self.tint = tint
    self.playbackRateTitle = playbackRateTitle
    self.captionVerticalOffset = captionVerticalOffset
    self.onPlaybackRateSelected = onPlaybackRateSelected
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 8) {
      backwardButton()
      playButton()
      forwardButton()
    }
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity)
    .overlay(alignment: .topLeading) {
      playbackRateMenu
    }
    .overlay(alignment: .topTrailing) {
      replayButton()
    }
  }
}

extension AudioPlayerControlView {
  private var playbackRateMenu: some View {
    Menu {
      Button("1.0배속") { onPlaybackRateSelected(1) }
      Button("1.25배속") { onPlaybackRateSelected(1.25) }
      Button("1.5배속") { onPlaybackRateSelected(1.5) }
      Button("2.0배속") { onPlaybackRateSelected(2) }
    } label: {
      VStack(spacing: 4) {
        Text(playbackRateTitle)
          .pretendardFont(family: .SemiBold, size: 16)
          .foregroundStyle(tint)
          .frame(width: 44, height: 44)
        Text("배속")
          .pretendardFont(.medium11)
          .foregroundStyle(.neutral300)
          .offset(y: captionVerticalOffset)
      }
      .contentShape(Rectangle())
    }
    .accessibilityLabel("재생 배속")
    .accessibilityValue("\(playbackRateTitle)배속")
  }

  @ViewBuilder
  private func replayButton() -> some View {
    Button(action: onReplay) {
      controlColumn(
        systemImage: "arrow.counterclockwise",
        iconColor: tint,
        iconSize: CGSize(width: 24, height: 24),
        caption: "다시듣기"
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("처음부터 다시 듣기")
    .disabled(!isReplayEnabled)
    .opacity(isReplayEnabled ? 1 : 0.4)
  }

  @ViewBuilder
  private func backwardButton() -> some View {
    Button(action: onBackward) {
      controlColumn(
        systemImage: "backward.end.fill",
        iconColor: tint,
        iconSize: CGSize(width: 18, height: 24),
        caption: "15초"
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("15초 뒤로")
  }

  @ViewBuilder
  private func playButton() -> some View {
    Button(action: onTogglePlay) {
      controlColumn(
        systemImage: isPlaying ? "pause.fill" : "play.fill",
        iconColor: tint,
        iconSize: CGSize(width: 28, height: 32),
        caption: nil
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isPlaying ? "일시정지" : "재생")
  }

  @ViewBuilder
  private func forwardButton() -> some View {
    Button(action: onForward) {
      controlColumn(
        systemImage: "forward.end.fill",
        iconColor: tint,
        iconSize: CGSize(width: 18, height: 24),
        caption: "15초"
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("15초 앞으로")
  }

  /// 세 버튼이 동일한 baseline 으로 정렬되도록 VStack 구조 + caption 자리를 항상 확보한다.
  /// 아이콘 크기와 별도로 모든 컨트롤에 최소 44pt 터치 영역을 확보한다.
  @ViewBuilder
  private func controlColumn(
    systemImage: String,
    iconColor: Color,
    iconSize: CGSize,
    caption: String?
  ) -> some View {
    VStack(spacing: 4) {
      Image(systemName: systemImage)
        .resizable()
        .scaledToFit()
        .foregroundStyle(iconColor)
        .frame(width: iconSize.width, height: iconSize.height)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())

      Text(caption ?? " ")
        .pretendardFont(.medium11)
        .foregroundStyle(.neutral300)
        .opacity(caption == nil ? 0 : 1)
        .offset(y: captionVerticalOffset)
    }
  }
}
