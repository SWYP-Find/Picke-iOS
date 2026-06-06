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
        loadedContent()
      }
    }
    .background(Color.beige50.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .overlay(alignment: .bottom) {
      if !shouldShowSkeleton {
        primaryButton()
          .padding(.horizontal, PreVoteLayout.ctaHorizontalPadding)
          .padding(.bottom, PreVoteLayout.ctaBottomSpacing)
      }
    }
    .overlay(alignment: .top) {
      if !shouldShowSkeleton {
        navigationBar()
          .background(Color.clear)
          .padding(.top, 12)
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .zIndex(10)
      }
    }
    .onAppear { send(.onAppear) }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
        .toolbar(.hidden, for: .navigationBar)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  private var shouldShowSkeleton: Bool {
    store.isLoading || store.battle == nil
  }

  @ViewBuilder
  private func loadedContent() -> some View {
    if let battle = store.battle {
      GeometryReader { proxy in
        ZStack(alignment: .top) {
          backgroundImage(battle)
            .frame(width: proxy.size.width)

          ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
              Color.clear
                .frame(height: PreVoteLayout.contentOverlapTopOffset)

              Spacer()
                .frame(height: PreVoteLayout.contentGradientSpacerHeight(
                  titleLength: battle.titleLine1.count + battle.titleLine2.count,
                  summaryLength: battle.summary.count
                ))

              contentArea(battle)
            }
            .frame(width: proxy.size.width)
            .frame(minHeight: proxy.size.height, alignment: .top)
          }
          .scrollBounceBehavior(.basedOnSize)
          .scrollDisabled(true)
        }
        .ignoresSafeArea(edges: .top)
      }
    } else {
      PreVoteSkeletonView()
    }
  }
}

// MARK: - Background

extension PreVoteView {
  @ViewBuilder
  private func backgroundImage(_ battle: PreVoteBattle) -> some View {
    ZStack {
      if let urlString = battle.backgroundImageURL,
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

      VStack {
        Spacer()
        imageToContentGradient()
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: PreVoteLayout.backgroundImageHeight)
    .clipped()
  }

  @ViewBuilder
  private func imageToContentGradient() -> some View {
    LinearGradient(
      stops: [
        .init(color: .beige50.opacity(0), location: 0),
        .init(color: .beige50.opacity(0.55), location: 0.55),
        .init(color: .beige50, location: 1),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(height: PreVoteLayout.imageToContentGradientHeight)
  }
}

// MARK: - Navigation bar

extension PreVoteView {
  @ViewBuilder
  private func navigationBar() -> some View {
    HStack {
      Button { send(.backButtonTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 24, weight: .regular))
          .frame(width: 20, height: 10)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Spacer()

      Button {
        send(.shareTapped(snapshot: captureCardSnapshot()))
      } label: {
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 24, weight: .regular))
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .foregroundStyle(.beige50)
  }
}

// MARK: - Content (gradient + 카피 + 선택지 + CTA)

extension PreVoteView {
  @ViewBuilder
  private func contentArea(_ battle: PreVoteBattle) -> some View {
    VStack(spacing: 0) {
      contentSection(battle)
      // 유연 간격: 콘텐츠는 위(상단 spacer)에 고정, 옵션은 아래로 당겨 CTA 위 40 유지.
      Spacer(minLength: PreVoteLayout.contentToOptionSpacing)
      optionSection(battle)
    }
    .padding(.horizontal, PreVoteLayout.contentHorizontalPadding)
    .padding(.top, PreVoteLayout.contentTopPadding)
    .padding(.bottom, PreVoteLayout.contentBottomSpacing)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(
      LinearGradient(
        stops: [
          .init(color: .beige50.opacity(0), location: 0),
          .init(color: .beige50.opacity(0.72), location: 0.42),
          .init(color: .beige50, location: 0.7),
          .init(color: .beige50, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .ignoresSafeArea(edges: .bottom)
  }

  @ViewBuilder
  private func contentSection(_ battle: PreVoteBattle) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 20) {
        tagsRow(battle)
        titleText(battle)
      }
      summaryText(battle)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func tagsRow(_ battle: PreVoteBattle) -> some View {
    HStack(spacing: 9) {
      ForEach(battle.tags, id: \.self) { tag in
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
  private func titleText(_ battle: PreVoteBattle) -> some View {
    Text([battle.titleLine1, battle.titleLine2].filter { !$0.isEmpty }.joined(separator: "\n"))
      .pretendardFont(family: .Bold, size: 24)
      .foregroundStyle(.neutral500)
      .kerning(-0.6)
      .lineSpacing(24 * 0.4)
      .multilineTextAlignment(.leading)
      .lineLimit(nil)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func summaryText(_ battle: PreVoteBattle) -> some View {
    Text(battle.summary)
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
  private func optionSection(_ battle: PreVoteBattle) -> some View {
    ZStack {
      HStack(spacing: 8) {
        optionCard(battle.leftOption)
        optionCard(battle.rightOption)
      }
      .frame(maxWidth: .infinity)
      vsBadge()
    }
  }

  @ViewBuilder
  private func optionCard(_ option: PreVoteOption) -> some View {
    let isSelected = store.selectedOptionId == option.optionId

    return Button {
      send(.optionTapped(optionId: option.optionId))
    } label: {
      VStack(spacing: 12) {
        avatarView(imageURL: option.imageURL)

        VStack(spacing: 2) {
          Text(option.stance)
            .pretendardFont(family: .SemiBold, size: 14)
            .foregroundStyle(.neutral600)
            .kerning(-0.35)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)

          Text(option.representative)
            .pretendardFont(family: .Medium, size: 12)
            .foregroundStyle(.neutral300)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity)
      .frame(height: PreVoteLayout.optionCardHeight)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(isSelected ? .beige700 : .beige500, lineWidth: 1)
      )
      .opacity(isSelected ? 1.0 : 0.88)
    }
    .buttonStyle(.plain)
  }

  private func avatarView(imageURL: String) -> some View {
    KFImage(URL(string: imageURL))
      .placeholder {
        SkeletonView()
          .frame(width: 28, height: 20)
      }
      .resizable()
      .scaledToFit()
      .frame(width: 28, height: 20)
      .frame(width: 40, height: 40)
      .background(.beige600, in: Circle())
  }

  @ViewBuilder
  private func vsBadge() -> some View {
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
  private func primaryButton() -> some View {
    CustomButton(
      action: { send(.primaryButtonTapped) },
      title: store.primaryButtonTitle,
      config: CustomButtonConfig.primary(.large, height: PreVoteLayout.ctaHeight),
      isEnable: store.isPrimaryButtonEnabled
    )
  }
}

// MARK: - Share snapshot

extension PreVoteView {
  @MainActor
  private func captureCardSnapshot() -> Data? {
    guard let battle = store.battle else { return nil }
    let renderer = ImageRenderer(content: shareSnapshotCard(battle))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage?.pngData()
  }

  @ViewBuilder
  private func shareSnapshotCard(_ battle: PreVoteBattle) -> some View {
    VStack(spacing: PreVoteLayout.contentToOptionSpacing) {
      contentSection(battle)
      optionSection(battle)
    }
    .padding(16)
    .frame(width: PreVoteLayout.snapshotWidth)
    .background(Color.beige50)
  }
}

#Preview {
  PreVoteView(
    store: Store(initialState: PreVoteFeature.State()) {
      PreVoteFeature()
    }
  )
}
