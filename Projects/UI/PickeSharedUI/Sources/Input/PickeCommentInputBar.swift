//
//  PickeCommentInputBar.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

/// 하단 고정 댓글 입력 바 — Android `PickeCommentInput`.
/// 바 beige600 + 위 1 구분선 beige700 + 그림자, 안쪽 16·간격 8, 입력 상자 최소 52(면 inputTextfield, 테두리 1, radius 2, 안쪽 12),
/// 글자 13 Medium textDefault(힌트 textMuted), 전송 40 원 primary500 + ic_send 24(아래 6).
public struct PickeCommentInputBar: View {
  @Binding private var text: String
  private let placeholder: String
  private let isSendEnabled: Bool
  private let isSubmitting: Bool
  private let onSend: () -> Void
  private var focus: FocusState<Bool>.Binding

  /// `isCompact` 는 예전 두 모양을 고르던 값이다. Android 는 한 모양만 있어 무시한다.
  public init(
    text: Binding<String>,
    focus: FocusState<Bool>.Binding,
    placeholder: String,
    isSendEnabled: Bool,
    isSubmitting: Bool = false,
    isCompact _: Bool = false,
    onSend: @escaping () -> Void
  ) {
    _text = text
    self.focus = focus
    self.placeholder = placeholder
    self.isSendEnabled = isSendEnabled
    self.isSubmitting = isSubmitting
    self.onSend = onSend
  }

  public var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      textBox
      sendButton
    }
    .padding(16)
    .topDivider(.beige700)
    .background {
      // 그림자는 바 배경에만 준다(안쪽 입력 상자·버튼에 번지지 않게).
      Rectangle()
        .fill(.beige600)
        .shadow(
          color: .black.opacity(0.12),
          radius: 8,
          y: -2
        )
        .ignoresSafeArea(edges: .bottom)
    }
  }
}

private extension PickeCommentInputBar {
  var textBox: some View {
    TextField(
      "",
      text: $text,
      prompt: Text(placeholder).foregroundStyle(.textMuted),
      axis: .vertical
    )
    .pretendardFont(.medium13)
    .foregroundStyle(.textDefault)
    .focused(focus)
    .lineLimit(1 ... 4)
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    .background(.inputTextfieldBackgroundDefault, in: RoundedRectangle(cornerRadius: .radiusDefault))
    .roundedBorder(
      .inputTextfieldBorderDefault,
      lineWidth: 1,
      radius: .radiusDefault,
      insideBorder: true
    )
  }

  var sendButton: some View {
    Button(action: onSend) {
      Image(asset: .send)
        .renderingMode(.template)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundStyle(.iconGrayInverse)
        .frame(width: 40, height: 40)
        .background(.buttonIconBackgroundDefault, in: Circle())
    }
    .buttonStyle(SendButtonStyle())
    .disabled(!isSendEnabled || isSubmitting)
    .padding(.bottom, 6)
    .accessibilityLabel("보내기")
  }
}

private struct SendButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}
