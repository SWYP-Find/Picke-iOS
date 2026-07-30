//
//  PreVoteView.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import SwiftUI

import BattleDomainInterface
import ComposableArchitecture
import Kingfisher
import PickeDesignKit

@ViewAction(for: PreVoteFeature.self)
public struct PreVoteView: View {
  @Bindable public var store: StoreOf<PreVoteFeature>

  public init(store: StoreOf<PreVoteFeature>) {
    self.store = store
  }

  // 안드로이드 시안: 사후(최종) 투표는 사전투표와 구분되도록 화면 배경을 통째로 검정으로 교체.
  // (VoteScreen.kt — PRE: surface, POST: Color.Black. 옵션 카드/CTA/상단바 색은 동일)
  private var isPostVote: Bool { store.voteMode == .post }
  private var screenBackground: Color { isPostVote ? .black : .beige50 }
  private var titleColor: Color { isPostVote ? .beige50 : .neutral500 }

  public var body: some View {
    Group {
      if shouldShowLoadError {
        loadErrorContent()
      } else if shouldShowSkeleton {
        PreVoteSkeletonView(isDark: isPostVote)
      } else {
        loadedContent()
      }
    }
    .background(screenBackground.ignoresSafeArea())
    .navigationBarHidden(true)
    .hidesSystemBars()
    .overlay(alignment: .top) {
      if !shouldShowSkeleton, !shouldShowLoadError {
        navigationBar()
          .background(.clear)
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

  /// 로드 실패 & 아직 표시할 배틀이 없을 때 무한 스켈레톤 대신 오류+재시도 노출.
  private var shouldShowLoadError: Bool {
    store.detailLoadFailed && store.battle == nil
  }

  private var shouldShowSkeleton: Bool {
    (store.isLoading || store.battle == nil || store.isCheckingParticipation) && !shouldShowLoadError
  }

  @ViewBuilder
  private func loadErrorContent() -> some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backButtonTapped) })
        .foregroundStyle(.neutral800)

      PickeRetryErrorView(message: "배틀을 불러오지 못했어요") { send(.retryTapped) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private func loadedContent() -> some View {
    if let battle = store.battle {
      GeometryReader { proxy in
        let topInset = PreVoteLayout.contentOverlapTopOffset
          + PreVoteLayout.contentGradientSpacerHeight(
            titleLength: battle.titleLine1.count + battle.titleLine2.count,
            summaryLength: battle.summary.count
          )

        ZStack(alignment: .top) {
          backgroundImage(battle)
            .frame(width: proxy.size.width)

          // 본문은 스크롤하지 않는다 — 옵션 카드는 항상 CTA 바로 위에 고정.
          let contentHeight = max(0, proxy.size.height - topInset - PreVoteLayout.ctaReservedHeight)
          VStack(spacing: 0) {
            Color.clear
              .frame(height: topInset)

            contentArea(battle, minHeight: contentHeight)
              .frame(height: contentHeight, alignment: .top)
          }
          .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
          .safeAreaInset(edge: .bottom, spacing: 0) {
            primaryButton()
              .padding(.horizontal, PreVoteLayout.ctaHorizontalPadding)
              .padding(.bottom, PreVoteLayout.ctaBottomSpacing)
          }
        }
        .ignoresSafeArea(edges: .top)
      }
    } else {
      PreVoteSkeletonView(isDark: isPostVote)
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
        .init(color: screenBackground.opacity(0), location: 0),
        .init(color: screenBackground.opacity(0.55), location: 0.55),
        .init(color: screenBackground, location: 1),
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
  private func contentArea(_ battle: PreVoteBattle, minHeight: CGFloat) -> some View {
    VStack(spacing: 0) {
      contentSection(battle)
      // 유연 간격: 콘텐츠는 위(상단 spacer)에 고정, 옵션은 아래로 당겨 CTA 위 40 유지.
      Spacer(minLength: PreVoteLayout.contentToOptionSpacing)
      optionSection(battle)
    }
    .padding(.horizontal, PreVoteLayout.contentHorizontalPadding)
    .padding(.top, PreVoteLayout.contentTopPadding)
    .padding(.bottom, PreVoteLayout.contentBottomSpacing)
    .frame(maxWidth: .infinity)
    // 큰 화면: 뷰포트를 채워 옵션을 하단 고정(기존 디자인). 작은 화면: 콘텐츠가 넘치면
    // 이 프레임이 그대로 늘어나 스크롤 영역이 되고, 옵션이 CTA 밑으로 잘리지 않는다.
    .frame(minHeight: minHeight, alignment: .top)
    .background(
      LinearGradient(
        stops: [
          .init(color: screenBackground.opacity(0), location: 0),
          .init(color: screenBackground.opacity(0.72), location: 0.42),
          .init(color: screenBackground, location: 0.7),
          .init(color: screenBackground, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
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
          .pickeBadge(.filled, size: .tag)
      }
    }
  }

  @ViewBuilder
  private func titleText(_ battle: PreVoteBattle) -> some View {
    Text([battle.titleLine1, battle.titleLine2].filter { !$0.isEmpty }.joined(separator: "\n"))
      .pretendardFont(.bold24)
      .foregroundStyle(titleColor)
      .kerning(-0.6)
      .lineSpacing(24 * 0.4)
      .multilineTextAlignment(.leading)
      .lineLimit(nil)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func summaryText(_ battle: PreVoteBattle) -> some View {
    Text(battle.summary)
      .pretendardFont(.regular13)
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
            .pretendardFont(.headingSmall)
            .foregroundStyle(.neutral600)
            .kerning(-0.35)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)

          Text(option.representative)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.neutral300)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.center)
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity)
      .frame(height: PreVoteLayout.optionCardHeight)
      .pickeCard(.beige300, border: isSelected ? .beige700 : .beige500)
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
      .pretendardFont(.bold11)
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
    Button(store.primaryButtonTitle) { send(.primaryButtonTapped) }
      .ctaButtonStyle(.primary, size: .large, height: PreVoteLayout.ctaHeight)
      .disabled(!store.isPrimaryButtonEnabled)
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
