//
//  BattleView.swift
//  Battle
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import ComposableArchitecture
import PickeSharedUI
import PickeDesignKit

@ViewAction(for: BattleFeature.self)
public struct BattleView: View {
  @Bindable public var store: StoreOf<BattleFeature>
  /// 현재 보이는 배틀 (세로 페이징) — 공유 시 대상 식별.
  @State private var currentBattleId: Int?

  public init(store: StoreOf<BattleFeature>) {
    self.store = store
  }

  /// 현재 보이는 배틀의 인덱스 (상단 paging 바 채움 기준). 스크롤 전엔 0.
  private var currentPageIndex: Int {
    guard let id = currentBattleId,
          let index = store.battles.firstIndex(where: { $0.id == id })
    else { return 0 }
    return index
  }

  public var body: some View {
    // Android `TodayBattleScreen` — 화면 배경은 순수 검정.
    ZStack {
      Color.black.ignoresSafeArea()

      if store.viewState == .loading {
        BattleSkeletonView()
      } else if store.battles.isEmpty {
        emptyState()
      } else {
        pager()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .top) {
      VStack(spacing: 0) {
        // 배틀이 여러 건일 때만 상단 paging 바 노출(Android: 위·좌우 16).
        if store.battles.count > 1 {
          BattlePagingBar(
            pageCount: store.battles.count,
            currentIndex: currentPageIndex,
            onSelect: { index in
              guard store.battles.indices.contains(index) else { return }
              let id = store.battles[index].id
              send(.pagingTapped(index: index))
              withAnimation(.easeInOut(duration: 0.25)) { currentBattleId = id }
            }
          )
          .padding([.horizontal, .top], 16)
        }
        appBar()
      }
      .zIndex(10)
    }
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
    // 데이터 로드 후 첫 페이지를 현재 배틀로 초기화 (스크롤 전엔 scrollPosition 이 nil).
    .onChange(of: store.battles.map(\.id)) { _, ids in
      if currentBattleId == nil { currentBattleId = ids.first }
    }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
    }
  }
}

// MARK: - Pager

private extension BattleView {
  @ViewBuilder
  func pager() -> some View {
    GeometryReader { proxy in
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 0) {
          ForEach(store.battles) { battle in
            battlePage(battle)
              .frame(width: proxy.size.width, height: proxy.size.height)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $currentBattleId)
      .scrollDisabled(store.battles.count <= 1)
    }
  }

  /// Android `BattleContent` + 하단 바 — 히어로(남는 높이 전부) → 32 → 선택지 → 16 → 버튼(16/16/16/20).
  @ViewBuilder
  func battlePage(_ battle: DailyBattle) -> some View {
    VStack(spacing: 0) {
      hero(battle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      vsOptions(battle)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 16)
      enterButton(battle)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
  }
}

// MARK: - Hero

private extension BattleView {
  /// 이미지를 꽉 채우고 위→아래 `[검정 0.2, 검정 0.6, 검정]` 그라데이션, 내용은 아래 가운데.
  @ViewBuilder
  func hero(_ battle: DailyBattle) -> some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .overlay {
          PickeRemoteImage(url: battle.imageURL) {
            SkeletonView(.rect, base: .gray600, highlight: .gray400)
          }
        }
        .overlay {
          LinearGradient(
            colors: [.black.opacity(0.2), .black.opacity(0.6), .black],
            startPoint: .top,
            endPoint: .bottom
          )
        }
        .clipped()
        .ignoresSafeArea(edges: .top)

      contentSection(battle)
        .padding(.horizontal, 16)
    }
  }
}

// MARK: - App Bar

private extension BattleView {
  /// Android `PickeTopAppBar`(투명) — 높이 48, 뒤로·공유 24 `textInverse`. 빈 화면에는 뒤로만.
  @ViewBuilder
  func appBar() -> some View {
    HStack(spacing: 0) {
      Button { send(.backTapped) } label: {
        appBarIcon(.arrowLeft)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("뒤로 가기")

      Spacer(minLength: 0)

      if let battleId = currentBattleId ?? store.battles.first?.battleId {
        Button { send(.shareTapped(battleId: battleId)) } label: {
          appBarIcon(.share)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("공유")
      }
    }
    .padding(.horizontal, 4)
    .frame(height: 48)
  }

  func appBarIcon(_ asset: ImageAsset) -> some View {
    Image(asset: asset)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .foregroundStyle(.textInverse)
      .frame(width: 24, height: 24)
      .frame(width: 48, height: 48)
      .contentShape(Rectangle())
  }
}

// MARK: - Content

private extension BattleView {
  @ViewBuilder
  func contentSection(_ battle: DailyBattle) -> some View {
    VStack(spacing: 0) {
      tagsRow(battle.tags)
      Text(battle.title)
        .pretendardFont(.bold24, lineSpacingMultiple: 1.3)
        .foregroundStyle(.textInverse)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 20)
      Text(battle.question)
        .pretendardFont(.bodyMedium, lineSpacingMultiple: 1.4)
        .foregroundStyle(.textMuted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 12)
      durationBadge(battle.durationText)
        .padding(.top, 16)
    }
    .frame(maxWidth: .infinity)
  }

  /// Android 태그 — `beige600` 면, radius 2, 최소 높이 20·가로 4, 12 SemiBold `textPrimary`, 간격 8.
  @ViewBuilder
  func tagsRow(_ tags: [String]) -> some View {
    HStack(spacing: 8) {
      ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
        Text("#\(tag)")
          .pretendardFont(.semiBold12)
          .foregroundStyle(.textPrimary)
          .padding(.horizontal, 4)
          .frame(minHeight: 20)
          .background(.beige600, in: RoundedRectangle(cornerRadius: .radiusDefault))
      }
    }
  }

  /// Android 시간 뱃지 — 테두리 1 `gray300` radius 2, 안쪽 13/7, 시계 16 + 4 + 12 SemiBold `textMuted`.
  @ViewBuilder
  func durationBadge(_ text: String) -> some View {
    HStack(spacing: 4) {
      Image(asset: .clock)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      Text(text)
        .pretendardFont(.semiBold12)
    }
    .foregroundStyle(.textMuted)
    .padding(.horizontal, 13)
    .padding(.vertical, 7)
    .roundedBorder(.gray300)
  }
}

// MARK: - VS Options

private extension BattleView {
  @ViewBuilder
  func vsOptions(_ battle: DailyBattle) -> some View {
    let options = battle.options
    let selectedId = store.selectedOptionByBattle[battle.battleId]
    ZStack {
      VStack(spacing: 12) {
        ForEach(options) { option in
          optionCard(option, isSelected: selectedId == option.id) {
            send(.optionTapped(battleId: battle.battleId, optionId: option.id))
          }
        }
      }

      if options.count > 1 {
        vsBadge
      }
    }
  }

  /// Android `OpinionCard` — 최소 높이 140, 안쪽 20/24, 이름 10 Bold `textSecondary` → 8 → 입장 18 SemiBold
  /// `textInverse` → 10 → 인용 12 Medium `textMuted`. 선택 `gray900` + `secondary500` 테두리, 그 외 `gray700`.
  @ViewBuilder
  func optionCard(
    _ option: DailyBattle.Option,
    isSelected: Bool,
    onTap: @escaping () -> Void
  ) -> some View {
    Button(action: onTap) {
      VStack(spacing: 0) {
        Text(option.representative)
          .pretendardFont(.bold10)
          .foregroundStyle(.textSecondary)
        Text(option.stance)
          .pretendardFont(family: .SemiBold, size: 18)
          .foregroundStyle(.textInverse)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 8)
        Text(option.quotedText)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.textMuted)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 10)
      }
      .multilineTextAlignment(.center)
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, minHeight: 140)
      .pickeCard(
        isSelected ? .gray900 : .gray700,
        border: isSelected ? .secondary500 : .clear
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// Android VS — 40 원 `secondary200`, 14 SemiBold `textDefault`, 테두리 없음.
  var vsBadge: some View {
    Text("VS")
      .pretendardFont(.headingSmall)
      .foregroundStyle(.textDefault)
      .frame(width: 40, height: 40)
      .background(.secondary200, in: Circle())
  }
}

// MARK: - CTA

private extension BattleView {
  /// Android `PickeButton` — 높이 48 이상, radius 2, 14 SemiBold, 비활성 `primary300`.
  @ViewBuilder
  func enterButton(_ battle: DailyBattle) -> some View {
    let isEnabled = store.selectedOptionByBattle[battle.battleId] != nil
    Button {
      send(.enterBattleTapped(battleId: battle.battleId))
    } label: {
      Text("배틀 입장하기")
        .pretendardFont(.headingSmall)
        .foregroundStyle(.surfaceBeigeDefault)
        .frame(maxWidth: .infinity, minHeight: 48)
        .roundedBackground(
          isEnabled ? .buttonPrimaryBackgroundDefault : .primary300,
          radius: .radiusDefault
        )
    }
    .buttonStyle(.plain)
    // `.disabled` 는 글자까지 흐리게 해서, 배경색만 바꾸고 누름만 막는다.
    .allowsHitTesting(isEnabled)
  }
}

// MARK: - Empty

private extension BattleView {
  /// Android 빈 화면 — 로고 160×120 `borderBeigeDefault`, 14 Regular `surfaceBeigeStrong` 가운데.
  @ViewBuilder
  func emptyState() -> some View {
    VStack(spacing: 0) {
      Image(asset: .appLogo)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.borderBeigeDefault)
        .frame(width: 160, height: 120)
      Text("아직 빠른 배틀이 선정되지 않았어요\n조금만 기다려주세요!")
        .pretendardFont(.bodyMedium, lineSpacingMultiple: 1.4)
        .foregroundStyle(.surfaceBeigeStrong)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
