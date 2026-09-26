import ComposableArchitecture
import AdDomainInterface
import SwiftUI
import PickeCoreLogger

/// 탐색과 동일한 서버 피드 광고를 단일 광고 위치에 표시한다.
/// 광고가 없거나 조회에 실패하면 다른 공급자로 전환하지 않고 숨긴다.
public struct FeedNativeAdView: View {
  private let insets: EdgeInsets
  private let onServerAdClick: (String) -> Void
  private let viewport: CGRect

  @Dependency(\.feedAdUseCase) private var feedAdUseCase
  @Environment(\.scenePhase) private var scenePhase
  @State private var serverAd: FeedAd?
  @State private var isLoading = true
  @State private var didRecordImpression = false

  public init(
    insets: EdgeInsets = EdgeInsets(),
    viewport: CGRect,
    onServerAdClick: @escaping (String) -> Void = { _ in }
  ) {
    self.insets = insets
    self.viewport = viewport
    self.onServerAdClick = onServerAdClick
  }

  public var body: some View {
    VStack(spacing: 0) {
      adContent()
    }
    .task {
      await loadServerAd()
    }
  }
}

extension FeedNativeAdView {
  @ViewBuilder
  private func adContent() -> some View {
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
    }
  }

  @MainActor
  private func loadServerAd() async {
    serverAd = nil
    didRecordImpression = false
    isLoading = true
    do {
      let ads = try await feedAdUseCase.fetchAds()
      guard !Task.isCancelled else { return }
      serverAd = ads.first
    } catch {
      guard !Task.isCancelled else { return }
      PickeLogger.error("[FeedAd] 광고 조회 실패: \(error.localizedDescription)", category: .ui)
    }
    isLoading = false
  }

  private func recordImpression(for ad: FeedAd) {
    guard scenePhase == .active, !didRecordImpression else { return }
    didRecordImpression = true
    Task {
      do {
        try await feedAdUseCase.recordImpressions(codes: [ad.code])
      } catch {
        PickeLogger.error("[FeedAd] 광고 노출 전송 실패: \(error.localizedDescription)", category: .ui)
      }
    }
  }
}
