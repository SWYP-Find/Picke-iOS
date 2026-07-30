//
//  NotificationView.swift
//  Notification
//

import SwiftUI

import ComposableArchitecture
import NotificationDomainInterface
import PickeDesignKit
import PickeFoundation

@ViewAction(for: NotificationFeature.self)
public struct NotificationView: View {
  @Bindable public var store: StoreOf<NotificationFeature>

  public init(store: StoreOf<NotificationFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "알림"
      ) {
        Button { send(.readAllTapped) } label: {
          Text("모두 읽음")
            .pretendardFont(.bodyMedium)
            .foregroundStyle(.gray300)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("notification.readAll")
      }
      .foregroundStyle(.gray500)

      tabBar()

      Group {
        if store.isLoading {
          NotificationSkeletonView()
        } else {
          content()
        }
      }
      .simultaneousGesture(tabSwipeGesture())
    }
    .screenBackground(.bgDefault)
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
        let tabs = NotificationCategory.allCases
        guard let index = tabs.firstIndex(of: store.selectedTab) else { return }
        if horizontal < 0, index < tabs.count - 1 {
          send(.tabSelected(tabs[index + 1]))
        } else if horizontal > 0, index > 0 {
          send(.tabSelected(tabs[index - 1]))
        }
      }
  }
}

private extension NotificationView {
  // MARK: 카테고리 탭 (전체/콘텐츠/공지사항/이벤트)

  @ViewBuilder
  func tabBar() -> some View {
    HStack(spacing: 8) {
      ForEach(NotificationCategory.allCases) { tab in
        tabPill(tab)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func tabPill(_ tab: NotificationCategory) -> some View {
    let isSelected = store.selectedTab == tab
    Button {
      send(.tabSelected(tab))
    } label: {
      Text(tab.title)
        .pretendardFont(.medium13)
        .foregroundStyle(isSelected ? .beige50 : .primary500)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .pickeCard(isSelected ? .primary500 : .primary50, border: isSelected ? .clear : .primary500)
    }
    .buttonStyle(.plain)
  }

  // MARK: 리스트

  @ViewBuilder
  func content() -> some View {
    if store.items.isEmpty {
      PickeEmptyStateView(message: "받은 알림이 없어요")
    } else {
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(store.items) { item in
            notificationRow(item)
              .onAppear {
                if item.id == store.items.last?.id {
                  send(.reachedBottom)
                }
              }
          }

          if store.isLoadingMore {
            ProgressView().padding(.vertical, 8)
          }
        }
        .padding(.top, 8)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
    }
  }

  /// 읽음 여부와 무관하게 알림 종류 아이콘을 유지한다. (읽음 표시는 색으로만 구분)
  func notificationIconName(_ item: NotificationItem) -> String {
    item.iconSystemName
  }

  @ViewBuilder
  func notificationRow(_ item: NotificationItem) -> some View {
    Button {
      send(.notificationTapped(item))
    } label: {
      HStack(alignment: .center, spacing: 16) {
        Image(systemName: notificationIconName(item))
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(item.isRead ? .gray300 : .primary500)
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 6) {
            Text(item.title)
              .pretendardFont(.labelSmall)
              .foregroundStyle(.gray300)
              .lineLimit(1)

            Spacer(minLength: 0)

            Text(item.createdAt.yearMonthDayDot)
              .pretendardFont(.labelSmall)
              .foregroundStyle(.gray300)
              .fixedSize()
          }

          Text(item.body)
            .pretendardFont(.headingSmall)
            .foregroundStyle(.gray500)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .pickeCard(.beige50, border: .beige600)
      .overlay(alignment: .topTrailing) {
        if !item.isRead {
          RoundedRectangle(cornerRadius: 3)
            .fill(.primary500)
            .frame(width: 4, height: 4)
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
      }
    }
    .buttonStyle(.plain)
  }
}
