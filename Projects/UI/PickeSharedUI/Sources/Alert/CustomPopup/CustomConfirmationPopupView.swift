//
//  CustomConfirmationPopupView.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

struct CustomConfirmationPopup: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  let title: String
  let message: String
  let confirmTitle: String
  let cancelTitle: String
  let isDestructive: Bool
  let style: CustomAlertStyle
  let onConfirm: () -> Void
  let onCancel: () -> Void

  @State private var isContentVisible = false
  @State var selectedReason: ReportReason?

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
          // Android 최종투표 대화상자는 바깥 터치도 "최종투표하기" 와 같다.
          .onTapGesture(perform: style == .finalVote ? onConfirm : onCancel)

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
}
