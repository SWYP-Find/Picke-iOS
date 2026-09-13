import ComposableArchitecture
import FeatureSharedUI
import AdDomainInterface
import SwiftUI

/// A single ad placement that alternates between a server ad and Kakao AdFit.
/// The selected source remains stable for the lifetime of the visible placement.
public struct MixedNativeAdView: View {
  private let unit: AdFitNativeAdUnit
  private let insets: EdgeInsets
  private let onAdClick: () -> Void
  private let onServerAdClick: (String) -> Void
  private let placementKey: String
  private let viewport: CGRect

  @Dependency(\.feedAdUseCase) private var feedAdUseCase
  @Environment(\.scenePhase) private var scenePhase
  @State private var serverAd: FeedAd?
  @State private var isLoading = true
  @State private var useServer = true
  @State private var hasAppeared = false
  @State private var didRecordImpression = false

  public init(
    unit: AdFitNativeAdUnit = .wide,
    insets: EdgeInsets = EdgeInsets(),
    placementKey: String = "default",
    viewport: CGRect,
    onAdClick: @escaping () -> Void = {},
    onServerAdClick: @escaping (String) -> Void = { _ in }
  ) {
    self.unit = unit
    self.insets = insets
    self.placementKey = placementKey
    self.viewport = viewport
    self.onAdClick = onAdClick
    self.onServerAdClick = onServerAdClick
  }

  public var body: some View {
    VStack(spacing: 0) {
      adContent()
    }
    .task {
      beginAppearanceIfNeeded()
      await loadServerAdIfNeeded()
    }
    .onDisappear { hasAppeared = false }
  }
}

private extension MixedNativeAdView {
  @ViewBuilder
  func adContent() -> some View {
    if let serverAd {
      FeedAdRow(
        ad: serverAd,
        viewport: viewport,
        onVisible: { recordImpression(for: serverAd) },
        onAdClick: { onServerAdClick(serverAd.network) }
      )
      .padding(insets)
    } else if isLoading {
      ProgressView()
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .padding(insets)
    } else {
      AdFitNativeAdView(
        unit: unit,
        insets: insets,
        onAdClick: onAdClick
      )
    }
  }

  func beginAppearanceIfNeeded() {
    guard !hasAppeared else { return }
    hasAppeared = true
    didRecordImpression = false
    serverAd = nil
    isLoading = false
    useServer = !UserDefaults.standard.bool(forKey: placementKey)
    UserDefaults.standard.set(useServer, forKey: placementKey)
    isLoading = useServer
  }

  @MainActor
  func loadServerAdIfNeeded() async {
    guard hasAppeared, useServer else { return }
    isLoading = true
    let result = try? await feedAdUseCase.fetchAds()
    guard !Task.isCancelled else { return }
    serverAd = result?.first
    isLoading = false
  }

  func recordImpression(for ad: FeedAd) {
    guard scenePhase == .active, !didRecordImpression else { return }
    didRecordImpression = true
    Task {
      try? await feedAdUseCase.recordImpressions(codes: [ad.code])
    }
  }
}
