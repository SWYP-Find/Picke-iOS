//
//  PickeAnimationAssetTests.swift
//  PickeAnimationTests
//

import Testing

@testable import PickeAnimation

struct PickeAnimationAssetTests {
  /// 에셋 파일이 빠지거나 이름이 바뀌면 스플래시가 빈 화면으로 뜬다.
  /// 번들 로딩까지 확인해야 그 회귀를 여기서 잡는다.
  @Test
  func 모든_에셋이_번들에서_로드된다() {
    for asset in PickeAnimationAsset.allCases {
      #expect(asset.image != nil, "\(asset.rawValue) 를 번들에서 찾지 못했다")
    }
  }

  /// GIF 디코딩 비용 때문에 에셋당 한 번만 만들기로 했다.
  @Test
  func 같은_에셋은_디코딩된_이미지를_재사용한다() {
    #expect(PickeAnimationAsset.splashLogo.image === PickeAnimationAsset.splashLogo.image)
  }

  @Test
  func 에셋_파일명은_확장자를_포함한다() {
    #expect(PickeAnimationAsset.splashLogo.rawValue == "splashLogo.gif")
  }
}
