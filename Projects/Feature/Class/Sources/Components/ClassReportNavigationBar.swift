//
//  ClassReportNavigationBar.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import PickeDesignKit
import SwiftUI

struct ClassReportNavigationBar: View {
  let title: String
  let backAccessibilityIdentifier: String
  let onBack: () -> Void
  let onClose: (() -> Void)?

  init(
    title: String,
    backAccessibilityIdentifier: String = "chevron.left",
    onBack: @escaping () -> Void,
    onClose: (() -> Void)? = nil
  ) {
    self.title = title
    self.backAccessibilityIdentifier = backAccessibilityIdentifier
    self.onBack = onBack
    self.onClose = onClose
  }

  var body: some View {
    ZStack {
      titleLabel
      backSection()
    }
    .frame(height: 48)
  }
}

private extension ClassReportNavigationBar {
  var titleLabel: some View {
    Text(title)
      .pretendardFont(.headingMedium)
      .kerning(0)
      .foregroundStyle(.gray500)
      .lineLimit(1)
      .padding(.horizontal, 56)
  }

  @ViewBuilder
  func backSection() -> some View {
    HStack(spacing: 0) {
      backButton
      Spacer()
      if let onClose {
        Button(action: onClose) {
          closeIcon
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
        .accessibilityIdentifier("class-report-close")
      }
    }
    .padding(.horizontal, 6)
  }

  var backButton: some View {
    Button(action: onBack) {
      backIcon
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("뒤로")
    .accessibilityIdentifier(backAccessibilityIdentifier)
  }

  var backIcon: some View {
    Path { path in
      path.move(to: CGPoint(x: 17, y: 2))
      path.addLine(to: CGPoint(x: 7, y: 12))
      path.addLine(to: CGPoint(x: 17, y: 22))
    }
    .stroke(
      .gray900,
      style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
    )
    .frame(width: 24, height: 24)
  }

  var closeIcon: some View {
    Path { path in
      path.move(to: CGPoint(x: 5, y: 5))
      path.addLine(to: CGPoint(x: 19, y: 19))
      path.move(to: CGPoint(x: 19, y: 5))
      path.addLine(to: CGPoint(x: 5, y: 19))
    }
    .stroke(
      .gray900,
      style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
    )
    .frame(width: 24, height: 24)
  }
}
