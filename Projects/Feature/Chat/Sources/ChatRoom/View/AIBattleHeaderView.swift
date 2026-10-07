//
//  AIBattleHeaderView.swift
//  Chat
//

import PickeDesignKit
import SwiftUI

/// AI Battle의 선택된 402×133 Figma 컴포넌트 중 앱 헤더 영역.
/// 라운드 정보는 호출부가 제공하며, ChatRoom 시나리오에 없는 값을 추측하지 않는다.
struct AIBattleHeaderView: View {
  let title: String
  let round: Int
  let roundCount: Int
  let onBack: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20))
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)

        Text(title)
          .pretendardFont(.headingSmall)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .foregroundStyle(.neutral800)
      .padding(.horizontal, 16)
      .frame(height: 56)

      HStack(spacing: 12) {
        Text("ROUND \(round) · 입장에 반박해보세요")
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray500)

        Spacer(minLength: 8)

        HStack(spacing: 4) {
          ForEach(1 ... max(roundCount, 1), id: \.self) { index in
            Capsule()
              .fill(index == round ? Color.primary500 : Color.beige600)
              .frame(width: index == round ? 48 : 24, height: 4)
          }
        }
      }
      .padding(.horizontal, 16)
      .frame(height: 32)
    }
    .background(.beige50)
  }
}

#if DEBUG
  #Preview("AI Battle · 선택된 헤더") {
    VStack(spacing: 0) {
      Color.beige50.frame(height: 45)
      AIBattleHeaderView(
        title: "슬픔을 드러내지 않은 외로움을 비난할 수 있을까?",
        round: 1,
        roundCount: 3,
        onBack: {}
      )
    }
    .frame(width: 402, height: 133)
  }
#endif
