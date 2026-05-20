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
    HStack(spacing: 32) {
      backwardButton()
      playButton()
      forwardButton()
    }
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func backwardButton() -> some View {
    Button(action: onBackward) {
      VStack(spacing: 4) {
        Image(systemName: "backward.end.fill")
          .font(.system(size: 28))
          .foregroundStyle(.primary800)
        Text("15초")
          .pretendardFont(family: .Medium, size: 11)
          .foregroundStyle(.neutral300)
      }
      .frame(width: 55, height: 55)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func playButton() -> some View {
    Button(action: onTogglePlay) {
      Image(systemName: isPlaying ? "pause.fill" : "play.fill")
        .font(.system(size: 28))
        .foregroundStyle(.neutral900)
        .frame(width: 55, height: 55)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func forwardButton() -> some View {
    Button(action: onForward) {
      VStack(spacing: 4) {
        Image(systemName: "forward.end.fill")
          .font(.system(size: 28))
          .foregroundStyle(.primary800)
        Text("15초")
          .pretendardFont(family: .Medium, size: 11)
          .foregroundStyle(.neutral300)
      }
      .frame(width: 55, height: 55)
    }
    .buttonStyle(.plain)
  }
}
