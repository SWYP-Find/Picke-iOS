//
//  PickeAudioPlayerBar.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit
import SwiftUI

/// Android `AudioPlayerBar` — 슬라이더(20, 트랙 2·썸 12) + 시간(13 Regular) + 컨트롤 행(55).
/// 시나리오 청취 화면과 클래스 배틀 미리보기가 함께 쓴다.
public struct PickeAudioPlayerBar: View {
  private let isPlaying: Bool
  private let currentTime: TimeInterval
  private let totalDuration: TimeInterval
  private let playbackRateTitle: String
  private let isForwardEnabled: Bool
  private let isSeekEnabled: Bool
  private let onTogglePlay: () -> Void
  private let onSeek: (TimeInterval) -> Void
  private let onBackward: () -> Void
  private let onForward: () -> Void
  private let onPlaybackRateTapped: () -> Void
  private let onReplay: () -> Void

  private enum Metric {
    static let sliderHeight: CGFloat = 20
    static let trackHeight: CGFloat = 2
    static let thumbSize: CGFloat = 12
    static let controlRowHeight: CGFloat = 55
  }

  public init(
    isPlaying: Bool,
    currentTime: TimeInterval,
    totalDuration: TimeInterval,
    playbackRateTitle: String,
    isForwardEnabled: Bool = true,
    isSeekEnabled: Bool = true,
    onTogglePlay: @escaping () -> Void,
    onSeek: @escaping (TimeInterval) -> Void,
    onBackward: @escaping () -> Void,
    onForward: @escaping () -> Void,
    onPlaybackRateTapped: @escaping () -> Void,
    onReplay: @escaping () -> Void
  ) {
    self.isPlaying = isPlaying
    self.currentTime = currentTime
    self.totalDuration = totalDuration
    self.playbackRateTitle = playbackRateTitle
    self.isForwardEnabled = isForwardEnabled
    self.isSeekEnabled = isSeekEnabled
    self.onTogglePlay = onTogglePlay
    self.onSeek = onSeek
    self.onBackward = onBackward
    self.onForward = onForward
    self.onPlaybackRateTapped = onPlaybackRateTapped
    self.onReplay = onReplay
  }

  public var body: some View {
    VStack(spacing: 0) {
      slider
      timeRow()
      controlRow()
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .frame(maxWidth: .infinity)
    .background {
      Rectangle()
        .fill(.surfaceBeigeDefault)
        .ignoresSafeArea(edges: .bottom)
    }
  }
}

// MARK: - Slider

extension PickeAudioPlayerBar {
  private var progress: CGFloat {
    guard totalDuration > 0 else { return 0 }
    return min(max(CGFloat(currentTime / totalDuration), 0), 1)
  }

  private var slider: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(.textMuted)
          .frame(height: Metric.trackHeight)
        Rectangle()
          .fill(.primary500)
          .frame(width: width * progress, height: Metric.trackHeight)
        Circle()
          .fill(.primary500)
          .frame(width: Metric.thumbSize, height: Metric.thumbSize)
          .offset(x: (width - Metric.thumbSize) * progress)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            guard width > 0, totalDuration > 0 else { return }
            let ratio = min(max(value.location.x / width, 0), 1)
            onSeek(totalDuration * Double(ratio))
          }
      )
      .allowsHitTesting(isSeekEnabled)
    }
    .frame(height: Metric.sliderHeight)
  }

  @ViewBuilder
  private func timeRow() -> some View {
    HStack(spacing: 0) {
      Text(Self.timeString(currentTime))
      Spacer(minLength: 0)
      Text(Self.timeString(totalDuration))
    }
    .pretendardFont(.regular13)
    .foregroundStyle(.textMuted)
  }

  private static func timeString(_ seconds: TimeInterval) -> String {
    let total = max(Int(seconds), 0)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

// MARK: - Controls

extension PickeAudioPlayerBar {
  @ViewBuilder
  private func controlRow() -> some View {
    HStack(alignment: .bottom, spacing: 0) {
      playbackRateButton
      HStack(spacing: 12) {
        skipButton(
          .playBack,
          isEnabled: true,
          accessibilityLabel: "15초 뒤로",
          action: onBackward
        )
        playButton
        skipButton(
          .playForward,
          isEnabled: isForwardEnabled,
          accessibilityLabel: "15초 앞으로",
          action: onForward
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      replayButton
    }
    .frame(height: Metric.controlRowHeight)
  }

  private var playbackRateButton: some View {
    Button(action: onPlaybackRateTapped) {
      VStack(spacing: 0) {
        Text(playbackRateTitle)
          .pretendardFont(family: .Medium, size: 16)
          .foregroundStyle(.textDefault)
        caption("배속", color: .textMuted)
      }
      .frame(minWidth: 40)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("재생 배속")
    .accessibilityValue("\(playbackRateTitle)배속")
  }

  private var playButton: some View {
    Button(action: onTogglePlay) {
      Image(asset: isPlaying ? .playStop : .play)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.gray600)
        .frame(width: 22, height: 31)
        .padding(.vertical, 8)
        .frame(width: 55)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isPlaying ? "일시정지" : "재생")
  }

  private var replayButton: some View {
    Button(action: onReplay) {
      VStack(spacing: 0) {
        Image(asset: .replay)
          .resizable()
          .scaledToFit()
          .foregroundStyle(.textDefault)
          .frame(width: 24, height: 24)
        caption("다시듣기", color: .textMuted)
      }
      .frame(minWidth: 40)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("처음부터 다시 듣기")
  }

  @ViewBuilder
  private func skipButton(
    _ icon: ImageAsset,
    isEnabled: Bool,
    accessibilityLabel: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Spacer(minLength: 0)
        Image(asset: icon)
          .resizable()
          .scaledToFit()
          .foregroundStyle(isEnabled ? .gray600 : .gray200)
          .frame(width: 20, height: 20)
        caption("15초", color: isEnabled ? .textMuted : .gray200)
      }
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .accessibilityLabel(accessibilityLabel)
  }

  private func caption(
    _ text: String,
    color: Color
  ) -> some View {
    Text(text)
      .pretendardFont(.labelSmall)
      .foregroundStyle(color)
  }
}
