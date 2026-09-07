//
//  CustomConfirmationPopupView+Components.swift
//  DesignSystem
//
//  팝업 공통 헬퍼 뷰

import SwiftUI

import PickeDesignKit

extension CustomConfirmationPopup {
  /// 베이지 카드 + primary 보더 컨테이너 (width 313, top padding 20).
  func pickeAlertCard(
    opacity: Double = 1,
    @ViewBuilder content: () -> some View
  ) -> some View {
    content()
      .padding(.top, 20)
      .frame(maxWidth: 313)
      .pickeCard(
        .beige500,
        border: .primary500,
        lineWidth: 1.5
      )
      .opacity(opacity)
      .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
      .onTapGesture {}
  }

  /// 본문 텍스트 (14/Medium, primary800, 가운데, 좌우 20).
  func pickeBodyText(_ text: String) -> some View {
    Text(text)
      .pretendardFont(.labelMedium)
      .foregroundStyle(.primary800)
      .lineSpacing(14 * 0.4)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 20)
  }

  /// 좌(밝은)·우(primary) 2버튼 행. 좌/우 의미는 호출부가 결정.
  @ViewBuilder
  func pickeTwoButtonRow(
    leftTitle: String,
    leftAction: @escaping () -> Void,
    rightTitle: String,
    rightAction: @escaping () -> Void
  ) -> some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(spacing: 8) {
        pickeSecondaryButton(title: leftTitle, action: leftAction)
        pickePrimaryButton(title: rightTitle, action: rightAction)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    } else {
      HStack(spacing: 8) {
        pickeSecondaryButton(title: leftTitle, action: leftAction)
        pickePrimaryButton(title: rightTitle, action: rightAction)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    }
  }

  @ViewBuilder
  private func pickeSecondaryButton(
    title: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.primary800)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .roundedBackground(.secondary50, radius: 8)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func pickePrimaryButton(
    title: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.secondary50)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .roundedBackground(.primary500, radius: 8)
    }
    .buttonStyle(.plain)
  }
}
