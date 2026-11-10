//
//  CurationView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import BattleDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import PickeCoreUtility
import Ad

@ViewAction(for: CurationFeature.self)
public struct CurationView: View {
  public let store: StoreOf<CurationFeature>

  public init(store: StoreOf<CurationFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header()
      GeometryReader { viewport in
        if store.viewState == .loading, store.battles.isEmpty {
          CurationSkeletonView()
            .padding(.horizontal, 16)
            .padding(.top, 16)
        } else {
          battleList(viewport: viewport)
        }
      }
    }
    .background(.surfaceBeigeDefault)
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
  }
}

// MARK: - Header

private extension CurationView {
  /// Android `PickeTopAppBar` — 배경 surfaceBeigeDefault, 구분선 없음, 닫기 `ic_x` 14.
  @ViewBuilder
  func header() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: "더 흥미로운 배틀도 있어요!"
    ) {
      Button { send(.closeButtonTapped) } label: {
        Image(asset: .close)
          .resizable()
          .scaledToFit()
          .frame(width: 14, height: 14)
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("닫기")
    }
    .foregroundStyle(.textDefault)
    .background(.surfaceBeigeDefault)
  }
}

// MARK: - List

private extension CurationView {
  /// Android `RecommendScreen` LazyColumn — 좌우·위 16, 아래 80, 간격 16. 목록이 비어도 광고 자리만 남는다.
  @ViewBuilder
  func battleList(viewport: GeometryProxy) -> some View {
    ScrollView(showsIndicators: false) {
      LazyVStack(spacing: 16) {
        // 큐레이션 리스트 최상단 — 탐색과 동일한 서버 피드 광고.
        FeedNativeAdView(
          insets: EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0),
          viewport: viewport.frame(in: .global),
          onServerAdClick: { send(.serverAdClicked(network: $0)) }
        )
        ForEach(store.battles) { battle in
          battleCard(battle)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 80)
    }
  }
}

// MARK: - Battle Card

private extension CurationView {
  /// Android `RecommendItemCard` — 안쪽 12, radius 2, 면 surfaceBeigeDefault·테두리 borderBeigeDefault.
  @ViewBuilder
  func battleCard(_ battle: RecommendedBattle) -> some View {
    Button { send(.battleTapped(battleId: battle.battleId)) } label: {
      VStack(alignment: .leading, spacing: 0) {
        cardMetaRow(battle)
        Text(battle.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.textDefault)
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.top, 12)
        Text(battle.summary)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray400)
          .lineLimit(2)
          .truncationMode(.tail)
          .padding(.top, 6)
        cardVersus(battle)
          .padding(.top, 8)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .pickeCard(
        .surfaceBeigeDefault,
        border: .borderBeigeDefault,
        insideBorder: true
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func cardMetaRow(_ battle: RecommendedBattle) -> some View {
    HStack(spacing: 0) {
      Text(battle.tagLabel)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.primary500)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .roundedBackground(.borderBeigeDefault)
      Spacer(minLength: 0)
      HStack(spacing: 8) {
        MetaLabelView(
          asset: .clock,
          text: battle.durationLabel,
          spacing: 4
        )
        MetaLabelView(
          asset: .eye,
          text: "\(battle.viewCount)",
          spacing: 4
        )
      }
    }
  }

  @ViewBuilder
  func cardVersus(_ battle: RecommendedBattle) -> some View {
    HStack(spacing: 2) {
      opinionBox(battle.options[safe: 0])
      BattleVersusBadge()
      opinionBox(battle.options[safe: 1])
    }
  }

  /// Android 입장(`stance`) + 대표(`representative`) + 이미지.
  func opinionBox(_ option: RecommendedBattleOption?) -> some View {
    BattleOpinionBox(
      opinion: option?.stance ?? "",
      name: option?.representative ?? "",
      imageURL: option?.imageUrl.flatMap(URL.init(string:))
    )
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
