//
//  CustomConfirmationPopupView+Content.swift
//  DesignSystem
//
//  팝업 종류별 컨텐츠 뷰 구성

import SwiftUI

extension CustomConfirmationPopup {
  func popupMaxWidth(for containerWidth: CGFloat) -> CGFloat {
    max(0, min(containerWidth - popupHorizontalPadding * 2, 360))
  }

  var popupHorizontalPadding: CGFloat {
    switch style {
    case .confirmation:
      return 20
    case .finalVote, .report, .alreadyWatched, .deleteConfirm, .logout, .withdraw, .suggestTopic:
      return 0
    }
  }

  @ViewBuilder
  var popupContent: some View {
    switch style {
    case .confirmation:
      confirmationContent
    case .finalVote:
      finalVoteContent
    case .report:
      reportContent
    case .alreadyWatched:
      alreadyWatchedContent
    case .deleteConfirm:
      deleteConfirmContent
    case .logout, .withdraw:
      logoutWithdrawContent
    case .suggestTopic:
      suggestTopicContent
    }
  }

  /// 로그아웃/탈퇴 — 공통 팝업 스타일(무료 충전/다시 시청 팝업과 동일).
  /// 본문 + 라운드 2버튼(확정=왼쪽 밝은 secondary50 / 취소=오른쪽 primary500).
  var logoutWithdrawContent: some View {
    pickeAlertCard {
      VStack(spacing: 16) {
        pickeBodyText(title)

        pickeTwoButtonRow(
          leftTitle: confirmTitle, leftAction: onConfirm,
          rightTitle: cancelTitle, rightAction: onCancel
        )
      }
    }
  }

  /// 주제 제안 — 타이틀 + 본문 + 뒤로가기(왼쪽 밝은) / 제안하기(오른쪽 primary).
  var suggestTopicContent: some View {
    pickeAlertCard {
      VStack(spacing: 16) {
        VStack(spacing: 10) {
          Text(title)
            .pretendardFont(.headingMedium)
            .foregroundStyle(.primary800)
            .multilineTextAlignment(.center)

          if !message.isEmpty {
            pickeBodyText(message)
          }
        }

        pickeTwoButtonRow(
          leftTitle: cancelTitle, leftAction: onCancel,
          rightTitle: confirmTitle, rightAction: onConfirm
        )
      }
    }
  }

  var deleteConfirmContent: some View {
    VStack(spacing: 16) {
      Text(title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.neutral900)
        .lineSpacing(14 * 0.4)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)

      HStack(spacing: 0) {
        // 삭제하기 (왼쪽·밝은 버튼) = 확정(삭제)
        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.primary500)
            .lineSpacing(14 * 0.4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary50, in: Rectangle())
        }
        .buttonStyle(.plain)

        // 뒤로가기 (오른쪽·어두운 버튼) = 취소
        Button(action: onCancel) {
          Text(cancelTitle)
            .pretendardFont(.labelMedium)
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
    .frame(maxWidth: 313)
    .pickeCard(
      .beige500,
      border: .primary500,
      lineWidth: 1.5
    )
    .opacity(0.9)
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
    .onTapGesture {}
  }

  @ViewBuilder
  var alreadyWatchedContent: some View {
    VStack(spacing: 12) {
      VStack(spacing: 8) {
        Text(title)
          .pretendardFont(.headingMedium)
          .foregroundStyle(.primary800)
          .kerning(-0.4)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)

        if !message.isEmpty {
          Text(message)
            .pretendardFont(.medium13)
            .foregroundStyle(.neutral400)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
      }

      HStack(spacing: 0) {
        Button(action: onCancel) {
          Text(cancelTitle.isEmpty ? "취소" : cancelTitle)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.primary500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary50, in: Rectangle())
        }
        .buttonStyle(.plain)

        Button(action: onConfirm) {
          Text(confirmTitle.isEmpty ? "다시" : confirmTitle)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.secondary50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.primary500, in: Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.top, 24)
    .frame(maxWidth: 343)
    .pickeCard(
      .beige500,
      border: .primary500,
      lineWidth: 1.5,
      radius: 6
    )
    .onTapGesture {}
  }

  var confirmationContent: some View {
    VStack(spacing: 24) {
      VStack(spacing: 8) {
        Text(title)
          .pretendardFont(.bold18)
          .foregroundStyle(.neutral800)
          .multilineTextAlignment(.center)

        if !message.isEmpty {
          Text(message)
            .pretendardFont(.regular13)
            .foregroundStyle(.neutral400)
            .lineSpacing(13 * 0.4)
            .multilineTextAlignment(.center)
        }
      }

      HStack(spacing: 8) {
        if !cancelTitle.isEmpty {
          Button(action: onCancel) {
            Text(cancelTitle)
              .pretendardFont(.labelMedium)
              .foregroundStyle(.neutral500)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .roundedBackground(.beige600)
          }
          .buttonStyle(.plain)
        }

        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.beige50)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
              isDestructive ? Color.errorDefault : Color.primary500,
              in: RoundedRectangle(cornerRadius: .radiusDefault)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 28)
    .padding(.horizontal, 20)
    .frame(maxWidth: 320)
    .pickeCard(ComponentToken.Popup.background, border: ComponentToken.Popup.border)
    .onTapGesture {}
  }

  var finalVoteContent: some View {
    VStack(spacing: 16) {
      Text(title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.neutral900)
        .lineSpacing(14 * 0.4)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)

      HStack(spacing: 0) {
        Button(action: onCancel) {
          Text(cancelTitle)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.primary500)
            .lineSpacing(14 * 0.4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary50, in: Rectangle())
        }
        .buttonStyle(.plain)

        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(.labelMedium)
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
    .frame(maxWidth: 313)
    .pickeCard(
      .beige500,
      border: .primary500,
      lineWidth: 1.5
    )
    .opacity(0.9)
    .onTapGesture {}
  }
}
