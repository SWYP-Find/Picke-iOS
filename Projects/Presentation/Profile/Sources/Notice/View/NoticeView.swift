//
//  NoticeView.swift
//  Profile
//
//  공지사항 · 이벤트 UI — App Bar + 탭바(공지사항/이벤트) + 빈 콘텐츠.
//  API 미구현 — 현재는 항상 빈 상태.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: NoticeFeature.self)
public struct NoticeView: View {
  @Bindable public var store: StoreOf<NoticeFeature>

  public init(store: StoreOf<NoticeFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "공지사항 · 이벤트")
        .foregroundStyle(.gray500)

      tabBar()

      PickeEmptyStateView(message: emptyMessage)
        // 좌우 스와이프로 탭 전환
        .contentShape(Rectangle())
        .simultaneousGesture(tabSwipeGesture())
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
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

private extension NoticeView {
  @ViewBuilder
  func tabBar() -> some View {
    HStack(spacing: 0) {
      ForEach(NoticeTab.allCases) { tab in
        tabButton(tab)
      }
    }
    .overlay(alignment: .bottom) {
      Rectangle().fill(.neutral200).frame(height: 1)
    }
  }

  @ViewBuilder
  func tabButton(_ tab: NoticeTab) -> some View {
    let isSelected = store.selectedTab == tab
    Button {
      send(.tabSelected(tab))
    } label: {
      Text(tab.title)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(isSelected ? .primary500 : .gray300)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(isSelected ? Color.primary500 : Color.clear)
            .frame(height: 3)
        }
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
