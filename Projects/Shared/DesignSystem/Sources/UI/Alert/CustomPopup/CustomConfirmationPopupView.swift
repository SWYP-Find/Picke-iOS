//
//  CustomConfirmationPopupView.swift
//  DesignSystem
//

import SwiftUI

struct CustomConfirmationPopup: View {
  private let title: String
  private let message: String
  private let confirmTitle: String
  private let cancelTitle: String
  private let isDestructive: Bool
  private let style: CustomAlertStyle
  private let onConfirm: () -> Void
  private let onCancel: () -> Void

  @State private var isContentVisible = false

  init(
    title: String,
    message: String,
    confirmTitle: String,
    cancelTitle: String,
    isDestructive: Bool,
    style: CustomAlertStyle,
    onConfirm: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.title = title
    self.message = message
    self.confirmTitle = confirmTitle
    self.cancelTitle = cancelTitle
    self.isDestructive = isDestructive
    self.style = style
    self.onConfirm = onConfirm
    self.onCancel = onCancel
  }

  var body: some View {
    ZStack {
      Color.black
        .opacity(isContentVisible ? 0.6 : 0)
        .ignoresSafeArea()
        .onTapGesture(perform: onCancel)

      popupContent
        .padding(.horizontal, 20)
        .offset(y: isContentVisible ? 0 : 120)
        .opacity(isContentVisible ? 1 : 0)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.3)) {
        isContentVisible = true
      }
    }
  }

  @ViewBuilder
  private var popupContent: some View {
    switch style {
    case .confirmation:
      confirmationContent
    case .finalVote:
      finalVoteContent
    }
  }

  private var confirmationContent: some View {
    VStack(spacing: 24) {
      VStack(spacing: 8) {
        Text(title)
          .pretendardFont(family: .Bold, size: 18)
          .foregroundStyle(.neutral800)
          .multilineTextAlignment(.center)

        if !message.isEmpty {
          Text(message)
            .pretendardFont(family: .Regular, size: 13)
            .foregroundStyle(.neutral400)
            .lineSpacing(13 * 0.4)
            .multilineTextAlignment(.center)
        }
      }

      HStack(spacing: 8) {
        if !cancelTitle.isEmpty {
          Button(action: onCancel) {
            Text(cancelTitle)
              .pretendardFont(family: .Medium, size: 14)
              .foregroundStyle(.neutral500)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
          }
          .buttonStyle(.plain)
        }

        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.beige50)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
              isDestructive ? Color.errorDefault : Color.primary500,
              in: RoundedRectangle(cornerRadius: 2)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 28)
    .padding(.horizontal, 20)
    .frame(width: 320)
    .background(ComponentToken.Popup.background, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(ComponentToken.Popup.border, lineWidth: 1)
    )
    .onTapGesture {}
  }

  private var finalVoteContent: some View {
    VStack(spacing: 16) {
      Text(title)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.neutral900)
        .lineSpacing(14 * 0.4)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)

      HStack(spacing: 10) {
        Button(action: onCancel) {
          Text(cancelTitle)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.primary500)
            .lineSpacing(14 * 0.4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary50, in: Rectangle())
        }
        .buttonStyle(.plain)

        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.secondary50)
            .lineSpacing(14 * 0.4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.primary500, in: Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 20)
    .frame(width: 313)
    .background(.beige500, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(.primary500, lineWidth: 1.5)
    )
    .onTapGesture {}
  }
}
