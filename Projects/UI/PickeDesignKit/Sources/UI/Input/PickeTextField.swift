//
//  PickeTextField.swift
//  PickeDesignKit
//

import SwiftUI

/// 한 줄 입력 필드. beige50 배경 + beige600 테두리, 비어 있으면 gray300 플레이스홀더.
public struct PickeTextField: View {
  private let placeholder: String
  @Binding private var text: String
  private let height: CGFloat

  public init(
    _ placeholder: String,
    text: Binding<String>,
    height: CGFloat = 44
  ) {
    self.placeholder = placeholder
    self._text = text
    self.height = height
  }

  public var body: some View {
    ZStack(alignment: .leading) {
      if text.isEmpty {
        Text(placeholder)
          .pretendardFont(.labelMedium)
          .foregroundStyle(.gray300)
          .lineLimit(1)
      }
      TextField("", text: $text)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.gray800)
    }
    .padding(.horizontal, 8)
    .frame(height: height)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige50, border: .beige600)
  }
}
