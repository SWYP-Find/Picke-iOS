//
//  CommentReplySkeletonView.swift
//  Chat
//
//  대댓글 화면 로딩 placeholder (부모 댓글 + 답글 목록).
//

import SwiftUI

import DesignSystem

struct CommentReplySkeletonView: View {
  var replyCount: Int = 3

  var body: some View {
    VStack(spacing: 0) {
      parentCard()
        .padding(12)
        .background(.beige50)
        .overlay(alignment: .bottom) {
          Rectangle().fill(.beige600).frame(height: 1)
        }

      VStack(alignment: .leading, spacing: 8) {
        SkeletonView(cornerRadius: 4)
          .frame(width: 64, height: 14)
          .padding(.horizontal, 12)
          .padding(.top, 12)

        ForEach(0 ..< replyCount, id: \.self) { _ in
          card()
            .padding(.horizontal, 12)
        }
      }
      .padding(.bottom, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.beige50)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  @ViewBuilder
  private func parentCard() -> some View {
    card()
  }

  @ViewBuilder
  private func card() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 8) {
        SkeletonView(cornerRadius: 18)
          .frame(width: 36, height: 36)
        VStack(alignment: .leading, spacing: 4) {
          SkeletonView(cornerRadius: 4).frame(width: 90, height: 14)
          SkeletonView(cornerRadius: 4).frame(width: 56, height: 16)
        }
        Spacer()
      }
      SkeletonView(cornerRadius: 4).frame(maxWidth: .infinity).frame(height: 12)
      SkeletonView(cornerRadius: 4).frame(width: 220, height: 12)
      HStack {
        Spacer()
        SkeletonView(cornerRadius: 4).frame(width: 44, height: 14)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .roundedBackground(.beige50)
    .overlay {
      RoundedRectangle(cornerRadius: .radiusDefault).stroke(.beige600, lineWidth: 1)
    }
  }
}
