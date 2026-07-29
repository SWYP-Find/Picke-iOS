//
//  NoticeView.swift
//  Profile
//

import SwiftUI

import ComposableArchitecture
import Entity
import NotificationDomainInterface
import PickeDesignKit
import Utill

@ViewAction(for: NoticeFeature.self)
public struct NoticeView: View {
  @Bindable public var store: StoreOf<NoticeFeature>

  public init(store: StoreOf<NoticeFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "공지사항 · 이벤트"
      )
      .foregroundStyle(.gray500)

      if let item = store.selectedItem {
        detailContent(item)
      } else {
        tabBar()
        listContent()
      }
    }
    .screenBackground()
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
  }

  /// 좌우 드래그 → 인접 탭 전환.
  func tabSwipeGesture() -> some Gesture {
    DragGesture(minimumDistance: 20)
      .onEnded { value in
        let horizontal = value.translation.width
        let vertical = value.translation.height
        guard abs(horizontal) > abs(vertical), abs(horizontal) > 50 else { return }
        let tabs = NoticeTab.allCases
        guard let index = tabs.firstIndex(of: store.selectedTab) else { return }
        if horizontal < 0, index < tabs.count - 1 {
          send(.tabSelected(tabs[index + 1]))
        } else if horizontal > 0, index > 0 {
          send(.tabSelected(tabs[index - 1]))
        }
      }
  }
}

// MARK: - 목록

private extension NoticeView {
  @ViewBuilder
  func listContent() -> some View {
    Group {
      if store.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.currentItems.isEmpty {
        PickeEmptyStateView(message: emptyMessage)
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(store.currentItems) { item in
              noticeCard(item)
            }
          }
          .padding(16)
        }
        .scrollIndicators(.hidden)
      }
    }
    // 좌우 스와이프로 탭 전환
    .contentShape(Rectangle())
    .simultaneousGesture(tabSwipeGesture())
  }

  @ViewBuilder
  func noticeCard(_ item: NotificationItem) -> some View {
    Button {
      send(.itemTapped(item))
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        categoryBadge()

        Text(item.title)
          .pretendardFont(.labelMedium)
          .foregroundStyle(.gray500)
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.top, 12)

        Text(item.body)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.top, 4)

        Text(item.createdAt.yearMonthDayDot)
          .pretendardFont(.regular11)
          .foregroundStyle(.gray300)
          .padding(.top, 8)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .pickeCard(.beige50, border: .beige600)
    }
    .buttonStyle(.plain)
  }

  var emptyMessage: String {
    switch store.selectedTab {
    case .notice: "새로운 공지사항이 없습니다"
    case .event: "새로운 이벤트가 없습니다"
    }
  }
}

// MARK: - 상세

private extension NoticeView {
  @ViewBuilder
  func detailContent(_ item: NotificationItem) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        categoryBadge()

        Text(item.title)
          .pretendardFont(.labelMedium)
          .foregroundStyle(.gray500)
          .padding(.top, 16)

        Text(item.createdAt.yearMonthDayDot)
          .pretendardFont(.regular11)
          .foregroundStyle(.gray300)
          .padding(.top, 8)

        Text(item.body)
          .pretendardFont(.regular13)
          .foregroundStyle(.neutral400)
          .lineSpacing(13 * 0.4)
          .padding(.top, 24)

        Button { send(.backToListTapped) } label: {
          Text("목록")
            .pretendardFont(.semiBold13)
            .foregroundStyle(.beige50)
            .padding(.horizontal, 32)
            .padding(.vertical, 10)
            .roundedBackground(.primary500)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 48)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 24)
      .padding(.vertical, 32)
      .background(.beige50)
    }
    .scrollIndicators(.hidden)
  }
}

// MARK: - 공통

private extension NoticeView {
  @ViewBuilder
  func categoryBadge() -> some View {
    Text(store.selectedTab.title)
      .pickeBadge(.filled, size: .tag)
  }
}

// MARK: - 탭바

private extension NoticeView {
  @ViewBuilder
  func tabBar() -> some View {
    HStack(spacing: 0) {
      ForEach(NoticeTab.allCases) { tab in
        tabButton(tab)
      }
    }
    .bottomDivider(.neutral200)
  }

  @ViewBuilder
  func tabButton(_ tab: NoticeTab) -> some View {
    let isSelected = store.selectedTab == tab
    Button {
      send(.tabSelected(tab))
    } label: {
      Text(tab.title)
        .pretendardFont(.labelMedium)
        .foregroundStyle(isSelected ? .primary500 : .gray300)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .bottomDivider(isSelected ? .primary500 : .clear, height: 3)
    }
    .buttonStyle(.plain)
  }
}
