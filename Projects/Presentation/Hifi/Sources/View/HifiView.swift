//
//  HifiView.swift
//  Hifi
//
//  .pen `탐색 hifi 이미지` 기준 탐색 화면 UI.
//

import SwiftUI

import ComposableArchitecture
import Entity
import HomeDomainInterface
import Kingfisher
import PickeDesignKit
import Utill

@ViewAction(for: HifiFeature.self)
public struct HifiView: View {
  @Bindable public var store: StoreOf<HifiFeature>

  public init(store: StoreOf<HifiFeature>) {
    self.store = store
  }

  public var body: some View {
    // 상단 바는 스크롤 영향 없는 sticky 헤더 — Home 과 동일하게 VStack 최상단에 둔다.
    // (기존 `.safeAreaInset(edge: .top)` + 바 배경 `.ignoresSafeArea(edges: .top)` 조합은
    //  iPhone 13 mini / iOS 18.6 에서 상단 안전영역 인셋이 이중 계산돼 헤더가 아래로
    //  밀리는 기종-한정 오류를 유발했다.)
    VStack(spacing: 0) {
      fixedTopBar()
      contentArea()
    }
    .background(Color.beige50.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

// MARK: - Empty

private extension HifiView {
  @ViewBuilder
  func fixedTopBar() -> some View {
    VStack(spacing: 0) {
      HifiHeaderView { send(.notificationTapped) }
      categoryTabs()
      sortRow()
    }
    .background(.beige50)
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
      if store.isLoading, store.items.isEmpty {
        skeletonList()
      } else if store.items.isEmpty {
        emptyState()
      } else {
        exploreList()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
    .contentShape(Rectangle())
    .simultaneousGesture(categorySwipe)
  }

  @ViewBuilder
  func emptyState() -> some View {
    VStack(spacing: 8) {
      Image(asset: .noDataLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 135, height: 90)

      Text("새로운 콘텐츠가 없습니다")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.beige800)
    }
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
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(store.items) { item in
          exploreRow(item)
            .onAppear {
              // 무한 스크롤: 마지막 아이템 노출 시 다음 페이지 로드
              if item.id == store.items.last?.id {
                send(.reachedBottom)
              }
            }
        }
      }
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
  }

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
    .padding(.horizontal, 16)
    .frame(height: 40)
    .background(.white)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige600).frame(height: 1.5)
    }
    .transaction { transaction in
      transaction.animation = nil
    }
  }

  @ViewBuilder
  func categoryTab(_ category: ExploreCategory) -> some View {
    let isSelected = store.selectedCategory == category
    Button { send(.categoryTapped(category)) } label: {
      // 각 탭은 가용 너비를 등분(maxWidth: .infinity) → 전체 너비 균등 분포 + 가로 움직임 제거.
      // 폰트 웨이트는 고정(Medium)해 글자 폭 변화로 인한 흔들림 제거.
      // 밑줄은 항상 자리(4px) 확보하고 색만 토글해 세로 레이아웃 재계산 방지.
      Text(category.title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(isSelected ? .primary500 : .gray300)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(isSelected ? .primary500 : .clear)
            .frame(height: 4)
        }
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        let isSelected = store.selectedSort == sort
        Button { send(.sortTapped(sort)) } label: {
          Text(sort.title)
            .pretendardFont(isSelected ? .semiBold12 : .labelSmall)
            .foregroundStyle(isSelected ? .beige50 : .primary500)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .roundedBackground(isSelected ? .primary500 : .bgDefault, radius: 4)
            .overlay(
              RoundedRectangle(cornerRadius: 4)
                .stroke(.primary500, lineWidth: 1)
            )
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
  @ViewBuilder
  func exploreRow(_ item: ExploreItem) -> some View {
    Button { send(.itemTapped(id: item.id)) } label: {
      HStack(alignment: .center, spacing: 8) {
        thumbnail(item.imageURL)

        VStack(alignment: .leading, spacing: 24) {
          VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
              Text("#\(item.category)")
                .pretendardFont(.semiBold12)
                .foregroundStyle(.primary500)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .roundedBackground(.beige600)

              Text(item.title)
                .pretendardFont(.headingSmall)
                .foregroundStyle(.neutral500)
                .kerning(-0.35)
                .lineSpacing(14 * 0.28)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(item.summary)
              .pretendardFont(.regular13)
              .foregroundStyle(.neutral400)
              .lineSpacing(13 * 0.4)
              .lineLimit(1)
              .truncationMode(.tail)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 2)
          }

          footer(item)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.beige50)
      .overlay(alignment: .bottom) {
        Rectangle().fill(.beige600).frame(height: 1)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func thumbnail(_ url: String?) -> some View {
    Group {
      if let url, let imageURL = URL(string: url) {
        KFImage(imageURL)
          .placeholder { Color.beige600 }
          .resizable()
          .scaledToFill()
      } else {
        Color.beige600
      }
    }
    .frame(width: 76)
    .frame(maxHeight: .infinity)
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
  }

  @ViewBuilder
  func footer(_ item: ExploreItem) -> some View {
    HStack(spacing: 6) {
      Spacer()
      HStack(spacing: 2) {
        Image(systemName: "clock")
          .font(.system(size: 11, weight: .regular))
        Text("\(item.minutes)분")
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(.neutral300)

      HStack(spacing: 2) {
        Image(systemName: "eye")
          .font(.system(size: 11, weight: .regular))
        Text(item.viewCount.decimalFormatted)
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(.neutral300)
    }
  }
}
