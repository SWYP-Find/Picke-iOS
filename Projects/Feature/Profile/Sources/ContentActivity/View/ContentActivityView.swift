//
//  ContentActivityView.swift
//  Profile
//

import SwiftUI

import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import ProfileDomainInterface

@ViewAction(for: ContentActivityFeature.self)
public struct ContentActivityView: View {
  @Bindable public var store: StoreOf<ContentActivityFeature>

  public init(store: StoreOf<ContentActivityFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "내 콘텐츠 활동"
      )
      .foregroundStyle(.gray500)

      tabBar()

      Group {
        if store.viewState == .loading {
          ContentActivitySkeletonView()
        } else {
          content()
        }
      }
      // 좌우 스와이프로 탭 전환 (CommentView 와 동일한 제스처 UX)
      .simultaneousGesture(tabSwipeGesture())
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
        let tabs = ContentActivityType.allCases
        guard let index = tabs.firstIndex(of: store.selectedTab) else { return }
        if horizontal < 0, index < tabs.count - 1 {
          send(.tabSelected(tabs[index + 1]))
        } else if horizontal > 0, index > 0 {
          send(.tabSelected(tabs[index - 1]))
        }
      }
  }
}

private extension ContentActivityView {
  // MARK: 탭바 (내 댓글 / 좋아요)

  @ViewBuilder
  func tabBar() -> some View {
    HStack(spacing: 0) {
      ForEach(ContentActivityType.allCases) { tab in
        tabButton(tab)
      }
    }
    .bottomDivider(.neutral200)
  }

  @ViewBuilder
  func tabButton(_ tab: ContentActivityType) -> some View {
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

  // MARK: 리스트

  @ViewBuilder
  func content() -> some View {
    if store.items.isEmpty {
      PickeEmptyStateView(message: emptyMessage)
    } else {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(store.items) { item in
            activityCard(item)
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
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
    }
  }

  var emptyMessage: String {
    switch store.selectedTab {
    case .comment: "작성한 댓글이 없어요"
    case .like: "좋아요한 댓글이 없어요"
    }
  }

  @ViewBuilder
  func activityCard(_ item: ContentActivity) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        avatar(item.author)

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 4) {
            Text(item.author.nickname)
              .pretendardFont(.labelMedium)
              .foregroundStyle(.gray500)
              .lineLimit(1)

            if !item.stanceText.isEmpty {
              Text(item.stanceText)
                .pickeBadge(.filled, size: .compact)
            }
          }

          Text(item.createdAt.relativeKoreanString)
            .pretendardFont(.labelXSmall)
            .foregroundStyle(.gray300)
        }

        Spacer(minLength: 0)
      }

      Text(item.content)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray400)
        .lineLimit(4)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: 4) {
        Spacer(minLength: 0)
        Image(systemName: "heart")
          .font(.system(size: 13))
          .foregroundStyle(.gray300)
        Text("\(item.likeCount)")
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(
      .beige50,
      border: .beige600,
      radius: 8
    )
  }

  @ViewBuilder
  func avatar(_ author: ContentActivityAuthor) -> some View {
    // 디자인(Z5YAW): 항상 beige600 원 배경 위에 캐릭터/기본 아이콘.
    ZStack {
      if !author.characterImageURL.isEmpty, let url = URL(string: author.characterImageURL) {
        PickeRemoteImage(url: url) { EmptyView() }
          .content(.fit)
          .padding(3)
      } else {
        Image(systemName: "cat.fill")
          .font(.system(size: 16))
          .foregroundStyle(.gray300)
      }
    }
    .pickeAvatar(size: 36)
  }
}
