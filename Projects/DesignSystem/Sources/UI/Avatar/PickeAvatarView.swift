//
//  PickeAvatarView.swift
//  PickeDesignKit
//

import SwiftUI

import Kingfisher

/// 원형 아바타. 이미지가 없으면 이름 첫 글자를 대신 보여준다.
public struct PickeAvatarView: View {
  private let imageURL: String?
  private let fallback: String
  private let size: CGFloat
  private let imageScale: CGFloat

  public init(
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

  public var body: some View {
    avatarContent()
      .pickeAvatar(size: size)
  }

  @ViewBuilder
  private func avatarContent() -> some View {
    if let imageURL, let url = URL(string: imageURL) {
      KFImage(url)
        .placeholder { Color.beige600 }
        .resizable()
        .scaledToFill()
        .frame(width: 24, height: 24)
        .scaleEffect(imageScale)
    } else {
      Text(String(fallback.prefix(1)))
        .pickeAvatarFallback(size: size)
    }
  }
}
