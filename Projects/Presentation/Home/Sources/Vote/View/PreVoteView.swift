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
    ZStack(alignment: .top) {
      backgroundImage

      VStack(spacing: 0) {
        navigationBar
        Spacer(minLength: 0)
        contentArea
      }
    }
    .background(Color.beige50.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.6)])
        .toolbar(.hidden, for: .navigationBar)
    }
  }
}

// MARK: - Background

extension PreVoteView {
  private var backgroundImage: some View {
    ZStack {
      if let urlString = store.battle.backgroundImageURL,
         let url = URL(string: urlString)
      {
        KFImage(url)
          .placeholder { Color.neutral200 }
          .resizable()
          .scaledToFill()
      } else {
        Color.neutral200
      }

      Color.black.opacity(0.4)
    }
    .frame(height: 512)
    .clipped()
    .frame(maxWidth: .infinity, alignment: .top)
    .ignoresSafeArea(edges: .top)
  }
}

// MARK: - Navigation bar

extension PreVoteView {
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
  private var contentArea: some View {
    VStack(spacing: 40) {
      contentSection
      optionSection
      primaryButton
    }
    .padding(.horizontal, 16)
    .padding(.top, 80)
    .padding(.bottom, 40)
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

  private var titleText: some View {
    Text("\(store.battle.titleLine1)\n\(store.battle.titleLine2)")
      .pretendardFont(family: .Bold, size: 24)
      .foregroundStyle(.neutral500)
      .kerning(-0.6)
      .lineSpacing(24 * 0.4)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var summaryText: some View {
    Text(store.battle.summary)
      .pretendardFont(family: .Regular, size: 13)
      .foregroundStyle(.neutral400)
      .lineSpacing(13 * 0.4)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - 선택지

extension PreVoteView {
  private var optionSection: some View {
    ZStack {
      HStack(spacing: 8) {
        optionCard(store.battle.leftOption)
        optionCard(store.battle.rightOption)
      }
      vsBadge
    }
  }

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
            .foregroundStyle(.neutral600)
            .kerning(-0.35)
            .multilineTextAlignment(.center)

          Text(option.philosopher.rawValue)
            .pretendardFont(family: .Medium, size: 12)
            .foregroundStyle(.neutral300)
            .multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(8)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(isSelected ? .primary500 : .beige600, lineWidth: isSelected ? 1.5 : 1)
      )
      .opacity(isSelected ? 1.0 : 0.88)
    }
    .buttonStyle(.plain)
  }

  private func avatarView(_ philosopher: PhilosopherAvatar) -> some View {
    let asset: ImageAsset = switch philosopher {
    case .plato: .avatarPlato
    case .sartre: .avatarSartre
    case .sunja: .avatarSunja
    }

    return Image(asset: asset)
      .resizable()
      .scaledToFit()
      .frame(width: 40, height: 40)
      .background(.beige600, in: Circle())
  }

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
