//
//  AdFitBannerView.swift
//  PickeDesignKit
//

import SwiftUI

import AdFitSDK

/// AdFit 배너 광고 단위.
///
/// AdFit 콘솔에서 광고 단위 하나는 사이즈 하나에 고정 발급된다. 즉 광고 단위 코드와
/// `adUnitSize` 는 반드시 짝이 맞아야 하며, 어긋나면 렌더링 실패(에러 코드 4)가 난다.
/// 그래서 둘을 따로 받지 않고 한 타입에 묶어 호출부가 틀릴 수 없게 한다.
public enum AdFitBannerUnit: Sendable {
  case size320x50
  case size320x100
  case size320x480

  /// SDK 에 넘기는 규격 문자열.
  var adUnitSize: String {
    switch self {
    case .size320x50: "320x50"
    case .size320x100: "320x100"
    case .size320x480: "320x480"
    }
  }

  /// 배너 크기 — `adUnitSize`("320x50") 문자열 하나를 단일 진실로 파싱한다.
  /// 새 규격은 case 와 `adUnitSize` 문자열만 추가하면 폭·높이가 함께 따라온다.
  var size: CGSize {
    let dimensions = adUnitSize.split(separator: "x").compactMap { Int($0) }
    guard dimensions.count == 2 else { return CGSize(width: 320, height: 50) }
    return CGSize(width: CGFloat(dimensions[0]), height: CGFloat(dimensions[1]))
  }

  var height: CGFloat { size.height }

  /// 광고 단위 코드가 담긴 Info.plist 키.
  var infoPlistKey: String {
    switch self {
    case .size320x50: "ADFIT_BANNER_320X50"
    case .size320x100: "ADFIT_BANNER_320X100"
    case .size320x480: "ADFIT_BANNER_320X480"
    }
  }

  var clientId: String? {
    let id = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String
    return (id?.isEmpty == false) ? id : nil
  }
}

/// 배너 광고 1개를 노출하는 뷰.
///
/// 광고 단위 코드가 비어 있거나(xcconfig 미설정) 광고 수신에 실패하면 아무것도 그리지 않는다.
/// 빈 자리를 남기면 레이아웃에 구멍이 생기므로 뷰를 통째로 접는 쪽을 택했다.
public struct AdFitBannerView: View {
  private let unit: AdFitBannerUnit
  private let insets: EdgeInsets
  private let alignment: Alignment

  /// 배너 로드 진행 상태. 로딩 동안은 스켈레톤, 성공하면 광고, 실패하면 자리를 접는다.
  private enum LoadState {
    case loading
    case loaded
    case failed
  }

  @State private var orientation: UIDeviceOrientation = .unknown
  @State private var loadState: LoadState = .loading
  @State private var contentWidth: CGFloat = 0

  /// - Parameters:
  ///   - insets: 광고가 **실제로 노출될 때만** 적용되는 여백. 배너는 폭 320 고정이라
  ///     주변 콘텐츠와 좌측 라인을 맞추려면 호출부가 콘텐츠와 동일한 여백을 넘겨준다.
  ///     광고가 없으면 뷰가 통째로 접혀 이 여백도 남지 않는다.
  ///   - alignment: 고정폭 배너의 정렬. 콘텐츠 좌측에 맞추려면 `.leading`.
  public init(
    unit: AdFitBannerUnit = .size320x50,
    insets: EdgeInsets = EdgeInsets(),
    alignment: Alignment = .center
  ) {
    self.unit = unit
    self.insets = insets
    self.alignment = alignment
  }

  public var body: some View {
    if let clientId = unit.clientId, loadState != .failed {
      // 로드가 실제로 성공하기 전에는 높이 0 으로 자리를 접어 리스트에 빈 공간을 남기지 않고,
      // 성공 시 사용 가능한 폭을 채우며 규격 비율(예: 320:100)로 높이를 편다.
      // 실제 사용 폭을 SDK 에 넘겨 크리에이티브가 그 폭으로 렌더돼야 상위 clipped 에 안 잘린다.
      AdFitBannerPresentableView(
        clientId: clientId,
        adUnitSize: unit.adUnitSize
      )
      .onDidReceiveAd { _, error in
        // 노출할 광고가 없는 경우(에러 코드 2)도 포함해 실패하면 자리를 비운다.
        loadState = (error == nil) ? .loaded : .failed
      }
      .onSizeThatFits(orientation: $orientation, width: contentWidth)
      .frame(
        width: max(contentWidth, 1),
        height: loadState == .loaded ? bannerHeight : 0
      )
      .clipped()
      .opacity(loadState == .loaded ? 1 : 0)
      .frame(maxWidth: .infinity, alignment: alignment)
      // 광고가 있을 때만 콘텐츠와 같은 여백을 준다.
      .padding(loadState == .loaded ? insets : EdgeInsets())
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.width
      } action: { width in
        contentWidth = max(0, width - insets.leading - insets.trailing)
      }
    }
  }

  private var bannerHeight: CGFloat {
    guard contentWidth > 0 else { return unit.height }
    return contentWidth * unit.size.height / unit.size.width
  }
}
