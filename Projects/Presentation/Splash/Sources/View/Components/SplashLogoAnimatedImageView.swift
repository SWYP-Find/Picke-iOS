//
//  SplashLogoAnimatedImageView.swift
//  Splash
//
//  Created by Wonji Suh  on 5/14/26.
//

import SwiftUI
import SDWebImage

struct SplashLogoAnimatedImageView: UIViewRepresentable {
  private static let size = CGSize(width: 250, height: 250)
  private static let image = SDAnimatedImage(named: "splashLogo.gif")
  
  func makeUIView(context: Context) -> SDAnimatedImageView {
    let imageView = SDAnimatedImageView()
    imageView.image = Self.image
    imageView.contentMode = .scaleAspectFit
    imageView.maxBufferSize = UInt.max
    imageView.shouldIncrementalLoad = false
    imageView.autoPlayAnimatedImage = true
    imageView.startAnimating()
    return imageView
  }
  
  func updateUIView(_ imageView: SDAnimatedImageView, context: Context) {
    guard imageView.image !== Self.image else { return }
    imageView.image = Self.image
    imageView.startAnimating()
  }
}

extension SplashLogoAnimatedImageView {
  func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView: SDAnimatedImageView,
    context: Context
  ) -> CGSize? {
    Self.size
  }
}
