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
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .zIndex(10)
    }
    .overlay(alignment: .bottom) {
      primaryButton
        .padding(.horizontal, Self.ctaHorizontalPadding)
        .padding(.bottom, Self.ctaBottomSpacing)
    }
    .onAppear { send(.onAppear) }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.6)])
        .toolbar(.hidden, for: .navigationBar)
    }
  }

  private var shouldShowSkeleton: Bool {
    store.isLoading || store.battle == nil
  }

  @ViewBuilder
  private var loadedContent: some View {
    if let battle = store.battle {
      GeometryReader { proxy in
        ZStack(alignment: .top) {
          backgroundImage(battle)
            .frame(width: proxy.size.width)

          ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
              Color.clear
                .frame(height: Self.contentOverlapTopOffset)

              contentArea(battle)
            }
            .frame(width: proxy.size.width)
          }
          .scrollBounceBehavior(.basedOnSize)
        }
        .ignoresSafeArea(edges: .top)
      }
    } else {
      PreVoteSkeletonView()
    }
  }

  private static let contentOverlapTopOffset: CGFloat = 290
  private static let contentSectionSpacing: CGFloat = 32
  private static let optionCardHeight: CGFloat = 104
  private static let ctaHeight: CGFloat = 52
  private static let ctaBottomSpacing: CGFloat = 40
  private static let ctaHorizontalPadding: CGFloat = 20
  private static let contentBottomSpacing: CGFloat = ctaHeight + ctaBottomSpacing + contentSectionSpacing
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
    HStack {
      Button { send(.backButtonTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 24, weight: .regular))
          .frame(width: 20, height: 10)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Spacer()

      Button { send(.shareTapped) } label: {
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 24, weight: .regular))
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .foregroundStyle(.beige50)
  }
}

// MARK: - Content (gradient + 카피 + 선택지 + CTA)

extension PreVoteView {
  @ViewBuilder
  private func contentArea(_ battle: PreVoteBattle) -> some View {
    VStack(spacing: Self.contentSectionSpacing) {
      contentSection(battle)
      optionSection(battle)
    }
    .padding(.horizontal, 20)
    .padding(.top, 80)
    .padding(.bottom, Self.contentBottomSpacing)
    .frame(maxWidth: .infinity)
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
      vsBadge
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
            .foregroundStyle(.neutral700)
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
      .frame(maxWidth: .infinity)
      .frame(height: Self.optionCardHeight)
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
      config: CustomButtonConfig.primary(.large, height: Self.ctaHeight),
      isEnable: store.isPrimaryButtonEnabled
    )
  }
}

#Preview {
  PreVoteView(
    store: Store(initialState: PreVoteFeature.State(battle: .mock)) {
      PreVoteFeature()
    }
  )
}
