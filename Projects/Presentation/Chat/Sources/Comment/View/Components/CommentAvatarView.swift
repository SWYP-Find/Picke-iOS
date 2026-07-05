//
//  CommentAvatarView.swift
//  Chat
//
//  댓글 프로필 이미지 공통 뷰.
//

import SwiftUI

import DesignSystem
import Kingfisher

struct CommentAvatarView: View {
  let imageURL: String?
  let fallback: String
  let size: CGFloat
  let imageScale: CGFloat

  init(
    imageURL: String?,
    fallback: String,
    size: CGFloat,
    imageScale: CGFloat = 1.16
  ) {
    self.imageURL = imageURL
    self.fallback = fallback
    self.size = size
    self.imageScale = imageScale
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(.beige600)

      avatarContent()
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay(Circle().stroke(.beige600, lineWidth: 1))
  }
}

private extension CommentAvatarView {
  @ViewBuilder
  func avatarContent() -> some View {
    if let imageURL, let url = URL(string: imageURL) {
      KFImage(url)
        .placeholder { Color.beige600 }
        .resizable()
        .scaledToFill()
        .frame(width: 24, height: 24)
        .scaleEffect(imageScale)
    } else {
      Text(String(fallback.prefix(1)))
        .pretendardFont(size <= 36 ? .semiBold13 : .headingSmall)
        .foregroundStyle(.primary500)
    }
  }
}
