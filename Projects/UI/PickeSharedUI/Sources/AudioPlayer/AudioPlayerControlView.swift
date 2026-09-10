//
//  AudioPlayerControlView.swift
//  DesignSystem
//

import SwiftUI

import PickeDesignKit

public struct AudioPlayerControlView: View {
  @Binding private var isPlaying: Bool
  private let onBackward: () -> Void
  private let onTogglePlay: () -> Void
  private let onForward: () -> Void
  /// 아이콘 색상. 기본은 기존 동작(회색). 채팅방은 브라운(primary500)을 주입한다.
  private let tint: Color

  public init(
    isPlaying: Binding<Bool>,
    onBackward: @escaping () -> Void,
    onTogglePlay: @escaping () -> Void,
    onForward: @escaping () -> Void,
    tint: Color
  ) {
    _isPlaying = isPlaying
    self.onBackward = onBackward
    self.onTogglePlay = onTogglePlay
    self.onForward = onForward
    self.tint = tint
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
        iconColor: tint,
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
        iconColor: tint,
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
        iconColor: tint,
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
        .pretendardFont(.medium11)
        .foregroundStyle(.neutral300)
        .opacity(caption == nil ? 0 : 1)
    }
  }
}
