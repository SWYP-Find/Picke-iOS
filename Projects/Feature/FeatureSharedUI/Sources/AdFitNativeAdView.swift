//
//  AdFitNativeAdView.swift
//  Ad
//

import PickeCoreLogger
import SwiftUI
import UIKit

import AdFitSDK

/// AdFit 네이티브 광고 단위.
///
/// 네이티브도 광고 단위 하나가 비율 하나에 고정 발급되므로, 배너와 같은 사상으로
/// 비율과 광고 단위 코드를 한 타입에 묶어 호출부가 어긋날 수 없게 한다.
public enum AdFitNativeAdUnit: Sendable {
  /// 1:1 정사각형.
  case square
  /// 2:1 와이드.
  case wide

  /// 광고 단위 코드가 담긴 Info.plist 키.
  var infoPlistKey: String {
    switch self {
    case .square:
      return "ADFIT_NATIVE_1_1"
    case .wide:
      return "ADFIT_NATIVE_2_1"
    }
  }

  var clientId: String? {
    let id = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String
    return (id?.isEmpty == false) ? id : nil
  }
}

/// 네이티브 광고 1개를 노출하는 뷰.
///
/// 광고 단위 코드가 비어 있으면(xcconfig 미설정) 아무것도 그리지 않는다.
/// 네이티브는 높이가 콘텐츠에 따라 가변이라 배너처럼 크기를 못 박을 수 없다. 그래서
/// SDK 가 계산해 준 높이를 그대로 프레임에 반영하고, 광고가 없으면 SDK 가 높이 0 으로
/// 접어 주므로 실패 자리도 자연히 사라진다.
public struct AdFitNativeAdView: View {
  private let unit: AdFitNativeAdUnit
  private let insets: EdgeInsets
  private let onAdClick: () -> Void

  /// 광고 수신 완료 여부. 완료 전까지는 스켈레톤으로 자리를 잡는다.
  @State private var loaded = false
  /// 광고 수신 실패 여부. 재시도 대기 중에는 뷰를 접되 로더는 유지한다.
  @State private var failed = false
  /// - Parameters:
  ///   - unit: 노출할 네이티브 광고 비율.
  ///   - insets: 광고가 **실제로 노출될 때만** 적용되는 여백. 광고 단위가 없으면
  ///     뷰가 통째로 접혀 이 여백도 남지 않는다.
  ///   - onAdClick: 광고를 눌렀을 때. AdKit 은 분석 모듈을 의존하지 않으므로
  ///     트래킹은 호출한 화면이 담당한다.
  public init(
    unit: AdFitNativeAdUnit,
    insets: EdgeInsets = EdgeInsets(),
    onAdClick: @escaping () -> Void = {}
  ) {
    self.unit = unit
    self.insets = insets
    self.onAdClick = onAdClick
  }

  public var body: some View {
    if let clientId = unit.clientId {
      ZStack {
        if !loaded, !failed {
          GeometryReader { proxy in
            AdBannerSkeletonView(size: CGSize(width: proxy.size.width, height: 120))
          }
          .frame(height: 120)
        }

        AdFitNativeAdRepresentable(
          clientId: clientId,
          loaded: $loaded,
          failed: $failed,
          onReceive: {
            PickeLogger.info("AdFit 네이티브 광고 수신 성공: \(unit.infoPlistKey)", category: .ui)
          },
          onFailure: { error in
            let nsError = error as NSError
            PickeLogger.error("AdFit 네이티브 광고 수신 실패: \(unit.infoPlistKey), domain=\(nsError.domain), code=\(nsError.code), \(error.localizedDescription)", category: .ui)
          },
          onClick: onAdClick
        )
        .aspectRatio(unit.aspectRatio, contentMode: .fit)
        .opacity(loaded ? 1 : 0)
      }
      .frame(height: failed ? 0 : nil)
      .padding(failed ? EdgeInsets() : insets)
    }
  }
}

private extension AdFitNativeAdUnit {
  var aspectRatio: CGFloat {
    switch self {
    case .square:
      return 1
    case .wide:
      return 2
    }
  }
}

private struct AdFitNativeAdRepresentable: UIViewRepresentable {
  let clientId: String
  @Binding var loaded: Bool
  @Binding var failed: Bool
  let onReceive: () -> Void
  let onFailure: (Error) -> Void
  let onClick: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      clientId: clientId,
      loaded: $loaded,
      failed: $failed,
      onReceive: onReceive,
      onFailure: onFailure,
      onClick: onClick
    )
  }

  func makeUIView(context: Context) -> PlainNativeAdView {
    let nativeAdView = PlainNativeAdView(frame: .zero)
    context.coordinator.prepare(nativeAdView)
    DispatchQueue.main.async {
      context.coordinator.loadIfNeeded()
    }
    return nativeAdView
  }

  func updateUIView(
    _ uiView: PlainNativeAdView,
    context: Context
  ) {
    context.coordinator.updateRootViewController(from: uiView)
  }

  @MainActor
  final class Coordinator: NSObject, AdFitNativeAdLoaderDelegate, AdFitNativeAdDelegate {
    private let loader: AdFitNativeAdLoader
    private let loaded: Binding<Bool>
    private let failed: Binding<Bool>
    private let onReceive: () -> Void
    private let onFailure: (Error) -> Void
    private let onClick: () -> Void
    private weak var nativeAdView: PlainNativeAdView?
    private var nativeAd: AdFitNativeAd?
    private var retryTask: Task<Void, Never>?
    private var requestCount = 0
    private var isRequesting = false

    private static let retryDelays: [Duration] = [
      .seconds(15),
      .seconds(30),
      .seconds(60),
      .seconds(120),
    ]

    init(
      clientId: String,
      loaded: Binding<Bool>,
      failed: Binding<Bool>,
      onReceive: @escaping () -> Void,
      onFailure: @escaping (Error) -> Void,
      onClick: @escaping () -> Void
    ) {
      loader = AdFitNativeAdLoader(clientId: clientId)
      self.loaded = loaded
      self.failed = failed
      self.onReceive = onReceive
      self.onFailure = onFailure
      self.onClick = onClick
      super.init()
      loader.delegate = self
    }

    deinit {
      retryTask?.cancel()
    }

    func prepare(_ nativeAdView: PlainNativeAdView) {
      self.nativeAdView = nativeAdView
      loader.desiredMediaWidth = UIScreen.main.bounds.width
    }

    func loadIfNeeded() {
      guard !isRequesting, nativeAd == nil else {
        return
      }
      updateRootViewController()
      requestCount += 1
      isRequesting = true
      failed.wrappedValue = false
      loader.loadAd()
    }

    func updateRootViewController(from nativeAdView: UIView) {
      guard let rootViewController = nativeAdView.window?.rootViewController else {
        return
      }
      loader.rootViewController = rootViewController
      nativeAd?.rootViewController = rootViewController
    }

    func nativeAdLoaderDidReceiveAd(_ nativeAd: AdFitNativeAd) {
      guard let nativeAdView else {
        return
      }
      retryTask?.cancel()
      retryTask = nil
      isRequesting = false
      self.nativeAd = nativeAd
      nativeAd.delegate = self
      nativeAd.rootViewController = nativeAdView.window?.rootViewController
      nativeAd.bind(nativeAdView)
      failed.wrappedValue = false
      loaded.wrappedValue = true
      onReceive()
    }

    func nativeAdDidClickAd(_: AdFitNativeAd) {
      onClick()
    }

    func nativeAdLoaderDidFailToReceiveAd(
      _: AdFitNativeAdLoader,
      error: Error
    ) {
      isRequesting = false
      loaded.wrappedValue = false
      failed.wrappedValue = true
      onFailure(error)
      scheduleRetryIfNeeded(for: error)
    }

    private func updateRootViewController() {
      guard let nativeAdView else {
        return
      }
      updateRootViewController(from: nativeAdView)
    }

    private func scheduleRetryIfNeeded(for error: Error) {
      let nsError = error as NSError
      guard nsError.code == 113 else {
        return
      }

      let delayIndex = min(
        requestCount - 1,
        Self.retryDelays.count - 1
      )
      let delay = Self.retryDelays[delayIndex]
      retryTask?.cancel()
      retryTask = Task { @MainActor [weak self] in
        try? await Task.sleep(for: delay)
        guard !Task.isCancelled else {
          return
        }
        self?.loadIfNeeded()
      }
    }
  }
}
