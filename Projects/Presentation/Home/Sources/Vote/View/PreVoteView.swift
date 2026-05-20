//
//  PreVoteView.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Kingfisher

@ViewAction(for: PreVoteFeature.self)
public struct PreVoteView: View {
  @Bindable public var store: StoreOf<PreVoteFeature>

  public init(store: StoreOf<PreVoteFeature>) {
    self.store = store
  }

  public var body: some View {
    Group {
      if shouldShowSkeleton {
        PreVoteSkeletonView()
      } else {
        loadedContent
      }
    }
    .background(Color.beige50.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .overlay(alignment: .top) {
      navigationBar
        .background(Color.clear)
        .padding(.top, topInset)
        .zIndex(10)
    }
    .onAppear { send(.onAppear) }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.6)])
        .toolbar(.hidden, for: .navigationBar)
    }
  }

  private var shouldShowSkeleton: Bool {
    store.isLoading && store.battleDetail == nil
  }

  private var topInset: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .safeAreaInsets.top ?? 47
  }

  @ViewBuilder
  private var loadedContent: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        backgroundImage
          .frame(width: proxy.size.width)

        ScrollView(showsIndicators: false) {
          VStack(spacing: 0) {
            Color.clear
              .frame(height: Self.contentOverlapTopOffset)

            contentArea(
              minHeight: max(0, proxy.size.height - Self.contentOverlapTopOffset)
            )
          }
          .frame(width: proxy.size.width)
        }
        .scrollBounceBehavior(.basedOnSize)
      }
      .ignoresSafeArea(edges: .top)
    }
  }

  private static let contentOverlapTopOffset: CGFloat = 290
}

// MARK: - Background

extension PreVoteView {
  @ViewBuilder
  private var backgroundImage: some View {
    ZStack {
      if let urlString = store.battle.backgroundImageURL,
         let url = URL(string: urlString)
      {
        KFImage(url)
          .placeholder { SkeletonView() }
          .resizable()
          .scaledToFill()
      } else {
        Color.neutral200
      }

      Color.black.opacity(0.4)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 512)
    .clipped()
  }
}

// MARK: - Navigation bar

extension PreVoteView {
  @ViewBuilder
  private var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) }
    ) {
      Button { send(.shareTapped) } label: {
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 16, weight: .semibold))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
    }
    .foregroundStyle(.beige50)
  }
}

// MARK: - Content (gradient + 카피 + 선택지 + CTA)

extension PreVoteView {
  @ViewBuilder
  private func contentArea(minHeight: CGFloat) -> some View {
    VStack(spacing: 40) {
      contentSection
      optionSection

      Spacer(minLength: 40)

      primaryButton
    }
    .padding(.horizontal, 24)
    .padding(.top, 80)
    .padding(.bottom, 40)
    .frame(maxWidth: .infinity)
    .frame(minHeight: minHeight, alignment: .top)
    .background(
      LinearGradient(
        stops: [
          .init(color: Color.beige50.opacity(0), location: 0),
          .init(color: .beige50, location: 0.35),
          .init(color: .beige50, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .ignoresSafeArea(edges: .bottom)
  }

  @ViewBuilder
  private var contentSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 20) {
        tagsRow
        titleText
      }
      summaryText
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var tagsRow: some View {
    HStack(spacing: 9) {
      ForEach(store.battle.tags, id: \.self) { tag in
        Text(tag)
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
      }
    }
  }

  @ViewBuilder
  private var titleText: some View {
    Text("\(store.battle.titleLine1)\n\(store.battle.titleLine2)")
      .pretendardFont(family: .Bold, size: 24)
      .foregroundStyle(.neutral500)
      .kerning(-0.6)
      .lineSpacing(24 * 0.4)
      .multilineTextAlignment(.leading)
      .lineLimit(nil)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var summaryText: some View {
    Text(store.battle.summary)
      .pretendardFont(family: .Regular, size: 13)
      .foregroundStyle(.neutral400)
      .lineSpacing(13 * 0.4)
      .multilineTextAlignment(.leading)
      .lineLimit(nil)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - 선택지

extension PreVoteView {
  @ViewBuilder
  private var optionSection: some View {
    ZStack {
      HStack(spacing: 8) {
        optionCard(store.battle.leftOption)
        optionCard(store.battle.rightOption)
      }
      .frame(maxWidth: .infinity)
      vsBadge
    }
  }

  @ViewBuilder
  private func optionCard(_ option: PreVoteOption) -> some View {
    let isSelected = store.selectedSide == option.philosopher

    return Button {
      send(.optionTapped(option.philosopher))
    } label: {
      VStack(spacing: 12) {
        avatarView(option.philosopher)

        VStack(spacing: 2) {
          Text(option.stance)
            .pretendardFont(family: .SemiBold, size: 14)
            .foregroundStyle(.neutral700)
            .kerning(-0.35)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)

          Text(option.philosopher.rawValue)
            .pretendardFont(family: .Medium, size: 12)
            .foregroundStyle(.neutral300)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity, minHeight: 121)
      .padding(8)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(isSelected ? .beige700 : .beige500, lineWidth: 1)
      )
      .opacity(isSelected ? 1.0 : 0.72)
    }
    .buttonStyle(.plain)
  }

  private func avatarView(_ philosopher: PhilosopherAvatar) -> some View {
    Image(asset: philosopher.imageAsset)
      .resizable()
      .scaledToFit()
      .frame(width: 40, height: 40)
      .background(.beige600, in: Circle())
  }

  @ViewBuilder
  private var vsBadge: some View {
    Text("VS")
      .pretendardFont(family: .Bold, size: 11)
      .foregroundStyle(.neutral800)
      .frame(width: 28, height: 28)
      .background(.secondary200, in: Circle())
      .overlay(Circle().stroke(.beige50, lineWidth: 1.5))
  }
}

// MARK: - CTA

extension PreVoteView {
  @ViewBuilder
  private var primaryButton: some View {
    CustomButton(
      action: { send(.primaryButtonTapped) },
      title: "사전 투표하기",
      config: CustomButtonConfig.primary(.large, height: 52),
      isEnable: store.isPrimaryButtonEnabled
    )
  }
}

#Preview {
  PreVoteView(
    store: Store(initialState: PreVoteFeature.State()) {
      PreVoteFeature()
    }
  )
}
