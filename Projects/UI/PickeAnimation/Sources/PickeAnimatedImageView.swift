//
//  PickeAnimatedImageView.swift
//  PickeAnimation
//

import SDWebImage
import SwiftUI

/// GIF 애니메이션을 재생하는 공용 뷰.
/// SDWebImage 를 이 모듈 안에 가둬 화면 코드가 라이브러리를 모르게 한다.
public struct PickeAnimatedImageView: UIViewRepresentable {
  private let asset: PickeAnimationAsset
  private let size: CGSize

  public init(
    _ asset: PickeAnimationAsset,
    size: CGSize
  ) {
    self.asset = asset
    self.size = size
  }

  public func makeUIView(context _: Context) -> SDAnimatedImageView {
    let imageView = SDAnimatedImageView()
    imageView.image = asset.image
    imageView.contentMode = .scaleAspectFit
    imageView.maxBufferSize = .max
    imageView.shouldIncrementalLoad = false
    imageView.autoPlayAnimatedImage = true
    imageView.startAnimating()
    return imageView
  }

  public func updateUIView(
    _ imageView: SDAnimatedImageView,
    context _: Context
  ) {
    guard imageView.image !== asset.image else { return }
    imageView.image = asset.image
    imageView.startAnimating()
  }

  public func sizeThatFits(
    _: ProposedViewSize,
    uiView _: SDAnimatedImageView,
    context _: Context
  ) -> CGSize? {
    size
  }
}
