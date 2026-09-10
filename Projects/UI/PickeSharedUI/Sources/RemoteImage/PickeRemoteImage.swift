//
//  PickeRemoteImage.swift
//  PickeSharedUI
//

import Kingfisher
import PickeDesignKit
import SwiftUI

// MARK: - 원격 이미지 공용 컴포넌트

/// 이미지 로딩 라이브러리를 이 타입 안에 가둔다.
/// 화면 코드는 Kingfisher 를 import 하지 않는다.
public struct PickeRemoteImage<Placeholder: View>: View {
  private let url: URL?
  private let placeholder: () -> Placeholder

  private var contentMode: SwiftUI.ContentMode = .fill

  public init(
    url: URL?,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.url = url
    self.placeholder = placeholder
  }

  public init(
    url: String?,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.init(url: url.flatMap(URL.init(string:)), placeholder: placeholder)
  }

  public var body: some View {
    KFImage(url)
      .placeholder(placeholder)
      .resizable()
      .aspectRatio(contentMode: contentMode)
  }
}

public extension PickeRemoteImage {
  /// `.fill` 이 기본이다. 잘리면 안 되는 이미지에만 `.fit` 을 준다.
  func content(_ mode: SwiftUI.ContentMode) -> Self {
    var image = self
    image.contentMode = mode
    return image
  }
}

// MARK: - 기본 자리표시자

public extension PickeRemoteImage where Placeholder == SkeletonView {
  /// 자리표시자를 따로 주지 않으면 스켈레톤이 자리를 채운다.
  init(
    url: URL?,
    shape: SkeletonShape = .round()
  ) {
    self.init(url: url) { SkeletonView(shape) }
  }

  init(
    url: String?,
    shape: SkeletonShape = .round()
  ) {
    self.init(url: url) { SkeletonView(shape) }
  }
}
