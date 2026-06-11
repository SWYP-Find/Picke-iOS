//
//  CustomConfirmationPopupView.swift
//  DesignSystem
//

import SwiftUI

struct CustomConfirmationPopup: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
    GeometryReader { proxy in
      ZStack {
        Color.black
          .opacity(isContentVisible ? 0.6 : 0)
          .ignoresSafeArea()
          .onTapGesture(perform: onCancel)

        popupContent
          .frame(maxWidth: popupMaxWidth(for: proxy.size.width))
          .padding(.horizontal, popupHorizontalPadding)
          .offset(y: isContentVisible ? 0 : 120)
          .opacity(isContentVisible ? 1 : 0)
          .accessibilityAddTraits(.isModal)
      }
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.3)) {
        isContentVisible = true
      }
    }
  }

  private func popupMaxWidth(for containerWidth: CGFloat) -> CGFloat {
    max(0, min(containerWidth - popupHorizontalPadding * 2, 360))
  }

  private var popupHorizontalPadding: CGFloat {
    switch style {
    case .confirmation:
      return 20
    case .finalVote, .report, .alreadyWatched, .deleteConfirm, .logout, .withdraw, .suggestTopic:
      return 0
    }
  }

  @ViewBuilder
  private var popupContent: some View {
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

  /// 로그아웃/탈퇴 — 본문(title) + 확정(왼쪽 밝은) / 취소(오른쪽 primary).
  private var logoutWithdrawContent: some View {
    pickeAlertCard(opacity: 0.9) {
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
  private var suggestTopicContent: some View {
    pickeAlertCard {
      VStack(spacing: 16) {
        VStack(spacing: 10) {
          Text(title)
            .pretendardFont(family: .SemiBold, size: 16)
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

  // MARK: picke 공통 팝업 헬퍼

  /// 베이지 카드 + primary 보더 컨테이너 (width 313, top padding 20).
  private func pickeAlertCard(
    opacity: Double = 1,
    @ViewBuilder content: () -> some View
  ) -> some View {
    content()
      .padding(.top, 20)
      .frame(maxWidth: 313)
      .background(.beige500, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(.primary500, lineWidth: 1.5)
      )
      .opacity(opacity)
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .onTapGesture {}
  }

  /// 본문 텍스트 (14/Medium, primary800, 가운데, 좌우 20).
  private func pickeBodyText(_ text: String) -> some View {
    Text(text)
      .pretendardFont(family: .Medium, size: 14)
      .foregroundStyle(.primary800)
      .lineSpacing(14 * 0.4)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 20)
  }

  /// 좌(밝은)·우(primary) 2버튼 행. 좌/우 의미는 호출부가 결정.
  @ViewBuilder
  private func pickeTwoButtonRow(
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
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.primary800)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .background(.secondary50, in: RoundedRectangle(cornerRadius: 8))
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
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.secondary50)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
  }

  private var deleteConfirmContent: some View {
    VStack(spacing: 16) {
      Text(title)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.neutral900)
        .lineSpacing(14 * 0.4)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)

      HStack(spacing: 0) {
        // 삭제하기 (왼쪽·밝은 버튼) = 확정(삭제)
        Button(action: onConfirm) {
          Text(confirmTitle)
            .pretendardFont(family: .Medium, size: 14)
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
    .frame(maxWidth: 313)
    .background(.beige500, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(.primary500, lineWidth: 1.5)
    )
    .opacity(0.9)
    .clipShape(RoundedRectangle(cornerRadius: 2))
    .onTapGesture {}
  }

  @ViewBuilder
  private var alreadyWatchedContent: some View {
    VStack(spacing: 12) {
      VStack(spacing: 8) {
        Text(title)
          .pretendardFont(family: .SemiBold, size: 16)
          .foregroundStyle(.primary800)
          .kerning(-0.4)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)

        if !message.isEmpty {
          Text(message)
            .pretendardFont(family: .Medium, size: 13)
            .foregroundStyle(.neutral400)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
      }

      HStack(spacing: 0) {
        Button(action: onCancel) {
          Text(cancelTitle.isEmpty ? "취소" : cancelTitle)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.primary500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary50, in: Rectangle())
        }
        .buttonStyle(.plain)

        Button(action: onConfirm) {
          Text(confirmTitle.isEmpty ? "다시" : confirmTitle)
            .pretendardFont(family: .Medium, size: 14)
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
    .background(.beige500, in: RoundedRectangle(cornerRadius: 6))
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(.primary500, lineWidth: 1.5)
    )
    .onTapGesture {}
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
    .frame(maxWidth: 320)
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

      HStack(spacing: 0) {
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
    .frame(maxWidth: 313)
    .background(.beige500, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(.primary500, lineWidth: 1.5)
    )
    .opacity(0.9)
    .onTapGesture {}
  }

  @State private var selectedReason: ReportReason?

  @ViewBuilder
  private var reportContent: some View {
    VStack(spacing: 16) {
      reportHeader
      reasonGrid
      reportButtons
    }
    .padding(.top, 20)
    .frame(maxWidth: 343)
    .background(.beige500, in: RoundedRectangle(cornerRadius: 6))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(.primary500, lineWidth: 1.5)
    )
    .onTapGesture {}
  }

  @ViewBuilder
  private var reportHeader: some View {
    Text("신고사유")
      .pretendardFont(family: .SemiBold, size: 16)
      .foregroundStyle(.primary800)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
  }

  @ViewBuilder
  private var reasonGrid: some View {
    HStack(alignment: .top, spacing: 0) {
      reasonColumn(ReportReason.leftColumn)
      reasonColumn(ReportReason.rightColumn, fillSpacer: true)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .frame(height: 116)
  }

  @ViewBuilder
  private func reasonColumn(
    _ reasons: [ReportReason],
    fillSpacer: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(reasons) { reason in
        reasonRow(reason)
      }
      if fillSpacer {
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func reasonRow(_ reason: ReportReason) -> some View {
    Button {
      selectedReason = reason
    } label: {
      HStack(spacing: 6) {
        reasonRadio(isSelected: selectedReason == reason)
        Text(reason.title)
          .pretendardFont(family: .Medium, size: 14)
          .foregroundStyle(.neutral900)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func reasonRadio(isSelected: Bool) -> some View {
    ZStack {
      Circle()
        .stroke(.gray200, lineWidth: 3)
        .frame(width: 20, height: 20)
      if isSelected {
        Circle()
          .fill(.primary500)
          .frame(width: 10, height: 10)
      }
    }
  }

  @ViewBuilder
  private var reportButtons: some View {
    HStack(spacing: 10) {
      reportSubmitButton
      reportCancelButton
    }
  }

  @ViewBuilder
  private var reportSubmitButton: some View {
    Button(action: onConfirm) {
      Text(confirmTitle.isEmpty ? "신고하기" : confirmTitle)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.primary800)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.secondary50, in: Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(selectedReason == nil)
    .opacity(selectedReason == nil ? 0.5 : 1)
  }

  @ViewBuilder
  private var reportCancelButton: some View {
    Button(action: onCancel) {
      Text(cancelTitle.isEmpty ? "뒤로가기" : cancelTitle)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.secondary50)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.primary500, in: Rectangle())
    }
    .buttonStyle(.plain)
  }
}

public enum ReportReason: String, CaseIterable, Identifiable, Equatable {
  case commercial
  case repeat_
  case explicit
  case insult
  case other

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .commercial: "영리목적/홍보성"
    case .repeat_: "같은 내용 반복 게시"
    case .explicit: "음란성/선정성"
    case .insult: "욕설/인신공격"
    case .other: "기타"
    }
  }

  static let leftColumn: [ReportReason] = [.commercial, .explicit, .other]
  static let rightColumn: [ReportReason] = [.repeat_, .insult]
}
