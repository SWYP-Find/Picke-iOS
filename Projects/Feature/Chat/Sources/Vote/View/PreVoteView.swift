//
//  PreVoteView.swift
//  Chat
//
//  Created by Picke on 5/16/26.
//

import BattleDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI
import UIKit

@ViewAction(for: PreVoteFeature.self)
public struct PreVoteView: View {
  @Bindable public var store: StoreOf<PreVoteFeature>

  public init(store: StoreOf<PreVoteFeature>) {
    self.store = store
  }

  private var isPostVote: Bool {
    store.voteMode == .post
  }

  /// Android `VoteScreenStyle.containerColor` — 사전 `surfaceBeigeDefault`, 최종 검정.
  private var containerColor: Color {
    isPostVote ? .black : .surfaceBeigeDefault
  }

  public var body: some View {
    Group {
      if store.isBattleNotFound {
        battleNotFound()
      } else if shouldShowSkeleton {
        PreVoteSkeletonView(isDark: isPostVote)
      } else if let battle = store.battle {
        loadedContent(battle)
      }
    }
    .background(containerColor.ignoresSafeArea())
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
    .onChange(of: store.shareSnapshotRequest) { _, request in
      guard let request else { return }
      send(.shareSnapshotRendered(captureCardSnapshot(request)))
    }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
        .toolbar(.hidden, for: .navigationBar)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  private var shouldShowSkeleton: Bool {
    store.viewState == .loading || store.battle == nil || store.isCheckingParticipation
  }

  /// Android `VoteBattleNotFound` — `backgroundBeige` 상단 바 + 빈 상태 "해당 배틀은 존재하지 않습니다".
  @ViewBuilder
  private func battleNotFound() -> some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backButtonTapped) })
        .foregroundStyle(.textDefault)
      PickeEmptyStateView(message: "해당 배틀은 존재하지 않습니다")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .screenBackground()
  }

  /// Android `VoteContent` — 히어로(남는 높이 전부) → 24 → 선택지 → 32 → 하단 버튼(패딩 20).
  @ViewBuilder
  private func loadedContent(_ battle: PreVoteBattle) -> some View {
    VStack(spacing: 0) {
      heroSection(battle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      optionSection(battle)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 32)
      primaryButton
        .padding(20)
    }
    .overlay(alignment: .top) {
      navigationBar()
    }
  }
}

// MARK: - Hero

extension PreVoteView {
  /// Android `VoteBattleInfoSection` — 이미지를 꽉 채우고 위→아래 `[검정 0.3, 투명, 배경색]` 그라데이션.
  @ViewBuilder
  private func heroSection(_ battle: PreVoteBattle) -> some View {
    ZStack(alignment: .bottomLeading) {
      heroImage(battle)
      contentSection(battle, onDarkBackground: isPostVote)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
  }

  private func heroImage(_ battle: PreVoteBattle) -> some View {
    Color.clear
      .overlay {
        PickeRemoteImage(url: battle.backgroundImageURL) {
          heroPlaceholder
        }
      }
      .overlay {
        LinearGradient(
          colors: [.black.opacity(0.3), .clear, containerColor],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      .clipped()
      .ignoresSafeArea(edges: .top)
  }
}

extension PreVoteView {
  /// Android 이미지 로딩 shimmer — 최종투표는 `gray600`→`gray400`.
  @ViewBuilder
  private var heroPlaceholder: some View {
    if isPostVote {
      SkeletonView(.rect, base: .gray600, highlight: .gray400)
    } else {
      SkeletonView.beige(.rect)
    }
  }
}

// MARK: - Navigation bar

extension PreVoteView {
  /// 뒤로 가기는 iOS 기존 상단 바(`PickeNavigationBar`)를 쓰고, 공유만 Android 아이콘(20)을 쓴다.
  @ViewBuilder
  private func navigationBar() -> some View {
    PickeNavigationBar(onBack: { send(.backButtonTapped) }) {
      Button { send(.shareTapped) } label: {
        Image(asset: .share)
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("공유")
    }
    .foregroundStyle(.textInverse)
  }
}

// MARK: - Content (태그 + 제목 + 설명)

extension PreVoteView {
  @ViewBuilder
  private func contentSection(
    _ battle: PreVoteBattle,
    onDarkBackground: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      tagsRow(battle)
      Text(battle.displayTitle)
        .pretendardFont(.headingXXLarge, lineSpacingMultiple: 1.3)
        .foregroundStyle(onDarkBackground ? .surfaceBeigeDefault : .textDefault)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 16)
      Text(battle.summary)
        .pretendardFont(.bodyMedium, lineSpacingMultiple: 1.4)
        .foregroundStyle(onDarkBackground ? .gray400 : .textSubtle)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Android `VoteTagChip` — 흰색 0.8 면, radius 2, 안쪽 8/2, 12 Medium `primary500`, 간격 8.
  @ViewBuilder
  private func tagsRow(_ battle: PreVoteBattle) -> some View {
    HStack(spacing: 8) {
      ForEach(battle.tags, id: \.self) { tag in
        Text(tag)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: .radiusDefault))
      }
    }
  }
}

// MARK: - 선택지

extension PreVoteView {
  @ViewBuilder
  private func optionSection(
    _ battle: PreVoteBattle,
    avatarOverrides: [Int: UIImage] = [:]
  ) -> some View {
    ZStack {
      HStack(spacing: 8) {
        optionCard(battle.leftOption, avatarOverride: avatarOverrides[battle.leftOption.optionId])
        optionCard(battle.rightOption, avatarOverride: avatarOverrides[battle.rightOption.optionId])
      }
      // Android `height(IntrinsicSize.Max)` — 두 카드 높이를 큰 쪽에 맞춘다.
      .fixedSize(horizontal: false, vertical: true)
      vsBadge
    }
  }

  /// Android `VoteOptionCard` — `surfaceBeigeSubtle` 면, 선택 `secondary500` / 그 외 `borderBeigeDisabled`,
  /// 안쪽 세로 24·가로 16, 아바타 40 → 16 → 제목 16 SemiBold → 4 → 대표 10 SemiBold. 비선택 0.8.
  @ViewBuilder
  private func optionCard(
    _ option: PreVoteOption,
    avatarOverride: UIImage? = nil
  ) -> some View {
    let isSelected = store.selectedOptionId == option.optionId
    Button {
      send(.optionTapped(optionId: option.optionId))
    } label: {
      VStack(spacing: 0) {
        avatarView(imageURL: option.imageURL, override: avatarOverride)
        Text(option.stance)
          .pretendardFont(.headingMedium, lineSpacingMultiple: 1.3)
          .foregroundStyle(.textDefault)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 16)
        Text(option.representative)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.textSubtler)
          .padding(.top, 4)
      }
      .padding(.vertical, 24)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .pickeCard(
        .surfaceBeigeSubtle,
        border: isSelected ? .secondary500 : .borderBeigeDisabled
      )
      .opacity(isSelected ? 1 : 0.8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// Android `ProfileImage(40)` — `borderBeigeDefault` 원 + 가운데 2/3 크기 이미지(fit).
  @ViewBuilder
  private func avatarView(
    imageURL: String,
    override: UIImage? = nil
  ) -> some View {
    Circle()
      .fill(.borderBeigeDefault)
      .overlay {
        Group {
          if let override {
            Image(uiImage: override)
              .resizable()
              .scaledToFit()
          } else {
            PickeRemoteImage(url: imageURL) {
              Color.clear
            }
            .content(.fit)
          }
        }
        .frame(width: 40 * 2 / 3, height: 40 * 2 / 3)
      }
      .frame(width: 40, height: 40)
  }

  /// Android `VoteVersusBadge` — 36 원 `secondary200`, "VS" 14 Medium `textDefault`.
  private var vsBadge: some View {
    Text("VS")
      .pretendardFont(.labelMedium)
      .foregroundStyle(.textDefault)
      .frame(width: 36, height: 36)
      .background(.secondary200, in: Circle())
  }
}

// MARK: - CTA

extension PreVoteView {
  /// Android `PickeButton` — 높이 48 이상, radius 2, 14 SemiBold `surfaceBeigeDefault`, 비활성 `primary300`.
  private var primaryButton: some View {
    Button {
      send(.primaryButtonTapped)
    } label: {
      Text(store.primaryButtonTitle)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.surfaceBeigeDefault)
        .frame(maxWidth: .infinity, minHeight: 48)
        .roundedBackground(
          store.isPrimaryButtonEnabled ? .buttonPrimaryBackgroundDefault : .primary300,
          radius: .radiusDefault
        )
    }
    .buttonStyle(.plain)
    // `.disabled` 는 글자까지 흐리게 해서, Android 처럼 배경색만 바꾸고 누름만 막는다.
    .allowsHitTesting(store.isPrimaryButtonEnabled)
    .accessibilityAddTraits(store.isPrimaryButtonEnabled ? [] : .isStaticText)
  }
}

// MARK: - Share snapshot

extension PreVoteView {
  @MainActor
  private func captureCardSnapshot(_ request: ShareSnapshotRequest) -> Data? {
    guard let battle = store.battle else { return nil }
    let avatars = request.avatarImageData.compactMapValues(UIImage.init(data:))
    let renderer = ImageRenderer(content: shareSnapshotCard(battle, avatarOverrides: avatars))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage?.pngData()
  }

  @ViewBuilder
  private func shareSnapshotCard(
    _ battle: PreVoteBattle,
    avatarOverrides: [Int: UIImage]
  ) -> some View {
    VStack(spacing: 24) {
      // 스냅샷 배경은 모드와 무관하게 밝은색이라, 사후(post) 화면의 밝은 제목색을
      // 그대로 쓰면 베이지 위 베이지로 묻힌다 → 항상 어두운 제목색으로 고정.
      contentSection(battle, onDarkBackground: false)
      optionSection(battle, avatarOverrides: avatarOverrides)
    }
    .padding(16)
    .frame(width: 360)
    .background(.beige50)
  }
}

#Preview {
  PreVoteView(
    store: Store(initialState: PreVoteFeature.State()) {
      PreVoteFeature()
    }
  )
}
