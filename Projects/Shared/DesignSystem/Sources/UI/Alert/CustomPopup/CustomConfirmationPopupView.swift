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
        .padding(.horizontal, popupHorizontalPadding)
        .offset(y: isContentVisible ? 0 : 120)
        .opacity(isContentVisible ? 1 : 0)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.3)) {
        isContentVisible = true
      }
    }
  }

  private var popupHorizontalPadding: CGFloat {
    switch style {
    case .confirmation:
      20
    case .finalVote, .report:
      0
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
    .frame(width: 313)
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
    .frame(width: 343, height: 236)
    .background(.beige500, in: RoundedRectangle(cornerRadius: 6))
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
  private func reasonColumn(_ reasons: [ReportReason], fillSpacer: Bool = false) -> some View {
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
