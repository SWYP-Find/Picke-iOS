//
//  PickeRetryErrorView.swift
//  DesignSystem
//

import SwiftUI

public struct PickeRetryErrorView: View {
  private let message: String
  private let retryTitle: String
  private let onRetry: () -> Void

  public init(
    message: String,
    retryTitle: String = "다시 시도",
    onRetry: @escaping () -> Void
  ) {
    self.message = message
    self.retryTitle = retryTitle
    self.onRetry = onRetry
  }

  public var body: some View {
    VStack(spacing: 16) {
      Text(message)
        .pretendardFont(.headingMedium)
        .foregroundStyle(.neutral800)
        .multilineTextAlignment(.center)

      Button(action: onRetry) {
        Text(retryTitle)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral800)
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.beige600, lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
