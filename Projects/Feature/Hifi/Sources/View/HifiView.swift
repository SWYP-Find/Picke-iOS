//
//  HifiView.swift
//  Hifi
//
//  Created by Picke on 10/11/26.
//

import SwiftUI
import Ad
import FeatureSharedUI

import ComposableArchitecture
import HomeDomainInterface
import PickeSharedUI
import PickeCoreUtility
import PickeDesignKit

@ViewAction(for: HifiFeature.self)
public struct HifiView: View {
  @Bindable public var store: StoreOf<HifiFeature>

  public init(store: StoreOf<HifiFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      fixedTopBar()
      contentArea()
    }
    .screenBackground(.bgBeige)
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
  }
}

// MARK: - Empty

private extension HifiView {
  @ViewBuilder
  func fixedTopBar() -> some View {
    VStack(spacing: 0) {
      HifiHeaderView()
      categoryTabs()
      sortRow()
    }
    .background(.bgBeige)
    .frame(maxWidth: .infinity)
    .zIndex(1)
    // 스크롤 중 상단 바가 슬라이드·어긋나 보이던 13 mini/iOS 18.6 잔상 제거.
    // (탭에만 animation=nil 이 걸려 헤더·정렬만 애니메이션 슬라이드해 순간적으로
    //  탭이 헤더 위로 올라간 듯 보이던 현상 — 상단 바 전체의 암묵 애니메이션을 끈다.)
    .transaction { $0.animation = nil }
  }

  @ViewBuilder
  func contentArea() -> some View {
    Group {
      if store.viewState == .loading, store.exploreItems.isEmpty {
        skeletonList()
      } else if store.exploreItems.isEmpty {
        emptyState()
      } else {
        exploreList()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // Android: 정렬 줄과 목록은 흰 바탕 위에 카드를 올린다.
    .background(.white)
    .clipped()
    .contentShape(Rectangle())
    .simultaneousGesture(categorySwipe)
    // 카테고리 전환 시 콘텐츠를 하드 컷 대신 부드럽게 디졸브 + 상단으로 리셋.
    // (상단 카테고리 바는 13 mini 안정성 위해 애니메이션 비활성 유지 — 콘텐츠 영역만 적용)
    .id(store.selectedCategory)
    .transition(.opacity)
    .animation(.easeInOut(duration: 0.2), value: store.selectedCategory)
  }

  @ViewBuilder
  func emptyState() -> some View {
    PickeEmptyStateView(message: "아직 준비된 배틀이 없어요!")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - List

private extension HifiView {
  @ViewBuilder
  func skeletonList() -> some View {
    ScrollView {
      ExploreSkeletonView()
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
  }

  @ViewBuilder
  func exploreList() -> some View {
    GeometryReader { viewport in
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 0) {
            Color.clear
              .frame(height: 0)
              .id(Self.topAnchorID)
            ForEach(store.exploreItems) { item in
              // Android: 카드 위마다 구분선, 마지막 카드 아래에도 한 줄.
              exploreRow(item, isLast: item.id == store.exploreItems.last?.id)
                .onAppear {
                  // 무한 스크롤: 마지막 아이템 노출 시 다음 페이지 로드
                  if item.id == store.exploreItems.last?.id {
                    send(.reachedBottom)
                  }
                }

              if let ad = store.withState({ state in
                state.exploreItems.firstIndex(where: { $0.id == item.id })
                  .flatMap { state.ad(after: $0) }
              }) {
                FeedAdRow(
                  ad: ad,
                  viewport: viewport.frame(in: .global),
                  onVisible: { send(.adVisible(code: ad.code, itemID: item.id)) },
                  onAdClick: { send(.serverAdClicked(network: ad.network)) }
                )
                .id(ad.code)
              }
            }
          }
          // 마지막 카드가 하단에 딱 붙지 않도록 10pt 여백.
          .padding(.bottom, 10)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .onChange(of: store.scrollToTopRequest) {
          withAnimation {
            proxy.scrollTo(Self.topAnchorID, anchor: .top)
          }
        }
      }
    }
  }

  static let topAnchorID = "exploreTop"

  /// 좌우 스와이프로 카테고리 전환 (빈 상태/스켈레톤 포함 콘텐츠 영역 전체에 적용).
  /// 인접 카테고리 계산은 Feature 가 담당.
  var categorySwipe: some Gesture {
    DragGesture(minimumDistance: 24)
      .onEnded { value in
        guard abs(value.translation.width) > abs(value.translation.height),
              abs(value.translation.width) > 50
        else { return }
        send(.swipedCategory(forward: value.translation.width < 0))
      }
  }
}

// MARK: - Category Tabs

private extension HifiView {
  @ViewBuilder
  func categoryTabs() -> some View {
    // Figma 3925-3747: 카테고리 탭은 전체 너비에 균등 분포(스크롤 없음).
    // 가로 ScrollView + 고정폭(50) 을 쓰면 소형 기종(13 mini)에서 폭이 넘쳐
    // 좌우로 움직이는(QA-39) 문제가 생기므로, 등분 HStack 으로 고정한다.
    HStack(spacing: 0) {
      ForEach(store.categories, id: \.self) { category in
        categoryTab(category)
          .frame(maxWidth: .infinity)
      }
    }
    // Android `PickeTabBar` — 화면 전체 폭, 배경 투명.
    .transaction { transaction in
      transaction.animation = nil
    }
  }

  @ViewBuilder
  func categoryTab(_ category: ExploreCategory) -> some View {
    Button { send(.categoryTapped(category)) } label: {
      // 각 탭은 가용 너비를 등분(maxWidth: .infinity) → 전체 너비 균등 분포 + 가로 움직임 제거.
      Text(category.title)
        .pickeSegmentTab(isSelected: store.selectedCategory == category)
    }
    .buttonStyle(.plain)
    .transaction { transaction in
      transaction.animation = nil
    }
  }
}

// MARK: - Sort

private extension HifiView {
  @ViewBuilder
  func sortRow() -> some View {
    HStack(spacing: 12) {
      ForEach(ExploreSort.allCases, id: \.self) { sort in
        Button { send(.sortTapped(sort)) } label: {
          Text(sort.title)
            .pickeSortChip(isSelected: store.selectedSort == sort)
        }
        .buttonStyle(.plain)
      }
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.white)
  }
}

// MARK: - List Row

private extension HifiView {
  /// Android `ExploreCard` — 가로 16·세로 14, 썸네일과 간격 12, 제목 → 6 → 요약, 아래에 시간·조회수.
  @ViewBuilder
  func exploreRow(
    _ item: ExploreItem,
    isLast: Bool
  ) -> some View {
    Button { send(.itemTapped(id: item.id)) } label: {
      HStack(alignment: .top, spacing: 12) {
        thumbnail(item.imageURL)
        rowText(item)
          .frame(height: Self.thumbnailHeight)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.surfaceBeigeDefault)
      .overlay(alignment: .top) {
        PickeDivider(.borderBeigeDefault)
      }
      .overlay(alignment: .bottom) {
        if isLast {
          PickeDivider(.borderBeigeDefault)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func rowText(_ item: ExploreItem) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 6) {
        Text("#\(item.category)")
          .pickeBadge(.filled, size: .tag)
        Text(item.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.textSubtler)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      Text(item.summary)
        .pretendardFont(.regular13, lineSpacingMultiple: 1.4)
        .foregroundStyle(.gray400)
        .lineLimit(2)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
      Spacer(minLength: 0)
      footer(item)
    }
  }

  static let thumbnailHeight: CGFloat = 80 * 4 / 3

  @ViewBuilder
  func thumbnail(_ url: String?) -> some View {
    Group {
      if let url, let imageURL = URL(string: url) {
        PickeRemoteImage(url: imageURL) { Color.beige600 }
      } else {
        Color.beige600
      }
    }
    // 행 높이와 무관하게 크기 고정 — 안드로이드 ExploreScreen (80dp, 3:4 비율) 파리티.
    .frame(width: 80, height: Self.thumbnailHeight)
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
  }

  /// Android 푸터 — 아이콘 16 `textMuted`, 4, 12 Medium `gray400`, 항목 간 12, 오른쪽 정렬.
  @ViewBuilder
  func footer(_ item: ExploreItem) -> some View {
    HStack(spacing: 12) {
      Spacer(minLength: 0)
      footerItem(.clock, text: "\(item.minutes)분")
      footerItem(.eye, text: item.viewCount.decimalFormatted)
    }
  }

  @ViewBuilder
  func footerItem(
    _ icon: ImageAsset,
    text: String
  ) -> some View {
    HStack(spacing: 4) {
      Image(asset: icon)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.textMuted)
        .frame(width: 16, height: 16)
      Text(text)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.gray400)
    }
  }
}
