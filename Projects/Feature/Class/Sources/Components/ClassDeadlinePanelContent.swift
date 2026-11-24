//
//  ClassDeadlinePanelContent.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import PickeDesignKit
import SwiftUI

struct ClassDeadlinePanelContent<Picker: View, CTA: View>: View {
  let message: String?
  @ViewBuilder let picker: () -> Picker
  @ViewBuilder let button: () -> CTA
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    VStack(spacing: 0) {
      panel()
    }
    .background(.white)
  }
}

private extension ClassDeadlinePanelContent {
  @ViewBuilder
  func panel() -> some View {
    if dynamicTypeSize.isAccessibilitySize {
      ScrollView {
        VStack(spacing: 20) {
          errorText
          picker().frame(height: 174)
          button().frame(height: 52)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
      }
    } else {
      VStack(spacing: 0) {
        errorText
          .frame(height: 26)
          .padding(.top, 18)
          .padding(.bottom, 2)
        picker().frame(height: 174)
        button()
          .frame(height: 52)
          .padding(.top, 20)
          .padding(.bottom, 8)
      }
      .padding(.horizontal, 16)
    }
  }

  var errorText: some View {
    Text(message ?? "")
      .pretendardFont(.regular13)
      .foregroundStyle(.red)
      .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel(message ?? "")
      .accessibilityHidden(message == nil)
      .accessibilityIdentifier("class-deadline-error")
  }
}
