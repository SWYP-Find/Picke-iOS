//
//  AudioPlayerControlView.swift
//  DesignSystem
//
//  .pen `Group 26` (재생바 컨트롤 3 버튼) 공통 컴포넌트.
//  채팅방 / 배틀 상세 등 오디오 플레이백이 필요한 화면에서 재사용.
//

import SwiftUI

public struct AudioPlayerControlView: View {
  @Binding private var isPlaying: Bool
  private let onBackward: () -> Void
  private let onTogglePlay: () -> Void
  private let onForward: () -> Void

  public init(
    isPlaying: Binding<Bool>,
    onBackward: @escaping () -> Void,
    onTogglePlay: @escaping () -> Void,
    onForward: @escaping () -> Void
  ) {
    _isPlaying = isPlaying
    self.onBackward = onBackward
    self.onTogglePlay = onTogglePlay
    self.onForward = onForward
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 32) {
      backwardButton()
      playButton()
      forwardButton()
    }
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func backwardButton() -> some View {
    Button(action: onBackward) {
      controlColumn(
        systemImage: "backward.end.fill",
        iconColor: .gray500,
        iconSize: CGSize(width: 24, height: 55),
        caption: "15초"
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func playButton() -> some View {
    Button(action: onTogglePlay) {
      controlColumn(
        systemImage: isPlaying ? "pause.fill" : "play.fill",
        iconColor: .gray500,
        iconSize: CGSize(width: 55, height: 55),
        caption: nil
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func forwardButton() -> some View {
    Button(action: onForward) {
      controlColumn(
        systemImage: "forward.end.fill",
        iconColor: .gray500,
        iconSize: CGSize(width: 24, height: 55),
        caption: "15초"
      )
    }
    .buttonStyle(.plain)
  }

  /// 세 버튼이 동일한 baseline 으로 정렬되도록 VStack 구조 + caption 자리를 항상 확보한다.
  /// `iconSize` 는 hit 영역 사이즈 — center play 는 55x55, 양옆 seek 는 24x55.
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
        .contentShape(Rectangle())

      Text(caption ?? " ")
        .pretendardCustomFont(textStyle: .medium11)
        .foregroundStyle(.neutral300)
        .opacity(caption == nil ? 0 : 1)
    }
  }
}
