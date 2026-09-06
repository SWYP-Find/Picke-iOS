//
//  PickeCommentInputBar.swift
//  PickeDesignKit
//

import SwiftUI

/// 하단 고정 댓글 입력 바.
public struct PickeCommentInputBar: View {
  @Binding private var text: String
  private let placeholder: String
  private let isSendEnabled: Bool
  private let onSend: () -> Void
  private var focus: FocusState<Bool>.Binding

  public init(
    text: Binding<String>,
    focus: FocusState<Bool>.Binding,
    placeholder: String,
    isSendEnabled: Bool,
    onSend: @escaping () -> Void
  ) {
    _text = text
    self.focus = focus
    self.placeholder = placeholder
    self.isSendEnabled = isSendEnabled
    self.onSend = onSend
  }

  public var body: some View {
    HStack(spacing: 8) {
      textBox()
      sendButton()
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 24)
    .frame(height: 128)
    .background(.surfaceBeigeStrong)
    .topDivider(.beige800)
    .shadow(color: .black.opacity(0.08), radius: 6, y: -4)
  }

  @ViewBuilder
  private func textBox() -> some View {
    TextField(placeholder, text: $text, axis: .vertical)
      .pretendardFont(.regular13)
      .foregroundStyle(.gray400)
      .focused(focus)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(.inputTextareaBackgroundDefault)
  }

  @ViewBuilder
  private func sendButton() -> some View {
    Button { onSend() } label: {
      Image(systemName: "paperplane.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.iconGrayInverse)
        .frame(width: 36, height: 36)
        .background(
          isSendEnabled ? .buttonIconBackgroundDefault : .buttonIconBackgroundDisabled,
          in: Circle()
        )
    }
    .buttonStyle(.plain)
    .disabled(!isSendEnabled)
  }
}
