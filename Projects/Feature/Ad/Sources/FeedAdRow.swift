import SwiftUI
import AdDomainInterface
import PickeSharedUI
import PickeDesignKit

public struct FeedAdRow: View {
  private let ad: FeedAd
  private let viewport: CGRect
  private let onVisible: () -> Void
  private let onAdClick: () -> Void
  @State private var isVisible = false
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var scenePhase

  public init(
    ad: FeedAd,
    viewport: CGRect,
    onVisible: @escaping () -> Void = {},
    onAdClick: @escaping () -> Void = {}
  ) {
    self.ad = ad
    self.viewport = viewport
    self.onVisible = onVisible
    self.onAdClick = onAdClick
  }

  public var body: some View {
    Button {
      if ["https", "http"].contains(ad.clickURL.scheme?.lowercased() ?? "") {
        onAdClick()
        openURL(ad.clickURL)
      }
    } label: {
      content()
    }
    .buttonStyle(.plain)
    .background {
      GeometryReader { geometry in
        Color.clear
          .preference(
            key: FeedAdVisibilityPreference.self,
            value: geometry.frame(in: .global).intersection(viewport).height > 0
              && geometry.frame(in: .global).intersects(viewport)
          )
      }
    }
    .onPreferenceChange(FeedAdVisibilityPreference.self) { visible in
      isVisible = visible
      if visible, scenePhase == .active { onVisible() }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active, isVisible { onVisible() }
    }
  }
}

extension FeedAdRow {
  @ViewBuilder
  private func content() -> some View {
    HStack(spacing: 12) {
      thumbnail()
      details()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige100)
  }

  @ViewBuilder
  private func thumbnail() -> some View {
    Group {
      PickeRemoteImage(url: ad.imageURL) { Color.beige600 }
    }
    .frame(width: 80, height: 100)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
  }

  @ViewBuilder
  private func details() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(ad.label)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.neutral400)
      Text(ad.title)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.neutral500)
        .lineLimit(2)
      Text(ad.subtitle)
        .pretendardFont(.regular13)
        .foregroundStyle(.neutral400)
        .lineLimit(1)
      Text(ad.ctaText)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.primary500)
    }
  }
}
