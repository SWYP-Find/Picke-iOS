//
//  PickeAnimationAsset.swift
//  PickeAnimation
//

import SDWebImage

/// 이 모듈이 번들로 갖고 있는 애니메이션 에셋.
/// 파일명을 화면 코드에 흘리지 않기 위해 여기서만 이름을 안다.
public enum PickeAnimationAsset: String, CaseIterable {
  case splashLogo = "splashLogo.gif"

  /// GIF 디코딩은 비용이 있어 에셋당 한 번만 만든다.
  var image: SDAnimatedImage? {
    Self.images[self] ?? nil
  }

  private static let images: [PickeAnimationAsset: SDAnimatedImage?] = {
    var loaded: [PickeAnimationAsset: SDAnimatedImage?] = [:]
    for asset in allCases {
      loaded[asset] = SDAnimatedImage(named: asset.rawValue, in: .pickeAnimation, compatibleWith: nil)
    }
    return loaded
  }()
}

private final class BundleToken {}

private extension Bundle {
  /// 이 모듈은 동적 프레임워크라 에셋이 자기 번들에 들어 있다.
  /// Tuist 가 리소스 접근자(`Bundle.module`)를 만들어주지 않아 직접 잡는다.
  static let pickeAnimation = Bundle(for: BundleToken.self)
}
