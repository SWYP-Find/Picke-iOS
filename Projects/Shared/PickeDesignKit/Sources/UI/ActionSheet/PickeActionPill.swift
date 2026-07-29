//
//  PickeActionPill.swift
//  PickeDesignKit
//

import SwiftUI

/// 아이콘 + 라벨 캡슐 액션 버튼. 액션 시트와 인라인 메뉴가 함께 쓴다.
public struct PickeActionPill: View {
  private let title: String
  private let systemImage: String
  private let action: () -> Void

  public init(
    title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: systemImage)
          .font(.system(size: 14, weight: .medium))
        Text(title)
          .pretendardFont(.medium13)
      }
      .foregroundStyle(.beige50)
      .padding(.horizontal, 16)
      .padding(.vertical, 9)
      .background(.primary500, in: Capsule())
    }
    .buttonStyle(.plain)
  }
}
