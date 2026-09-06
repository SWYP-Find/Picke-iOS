//
//  CustomConfirmationPopupView+Report.swift
//  DesignSystem
//
//  신고 팝업 전용 컨텐츠

import SwiftUI

extension CustomConfirmationPopup {
  @ViewBuilder
  var reportContent: some View {
    VStack(spacing: 16) {
      reportHeader
      reasonGrid
      reportButtons
    }
    .padding(.top, 20)
    .frame(maxWidth: 343)
    .roundedBackground(.beige500, radius: 6)
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .roundedBorder(
      .primary500,
      lineWidth: 1.5,
      radius: 6
    )
    .onTapGesture {}
  }

  @ViewBuilder
  private var reportHeader: some View {
    Text("신고사유")
      .pretendardFont(.headingMedium)
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
          .pretendardFont(.labelMedium)
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
        .pretendardFont(.labelMedium)
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
        .pretendardFont(.labelMedium)
        .foregroundStyle(.secondary50)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.primary500, in: Rectangle())
    }
    .buttonStyle(.plain)
  }
}
