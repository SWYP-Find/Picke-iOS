//
//  ContentActivityView.swift
//  Profile
//
//  내 콘텐츠 활동 UI — picke.pen `내 콘텐츠활동_댓글/좋아요`.
//  App Bar + 탭바(내 댓글/좋아요) + 카드 리스트 + 무한 스크롤.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Kingfisher
import Utill

@ViewAction(for: ContentActivityFeature.self)
public struct ContentActivityView: View {
  @Bindable public var store: StoreOf<ContentActivityFeature>

  public init(store: StoreOf<ContentActivityFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "내 콘텐츠 활동")
        .foregroundStyle(.gray500)

      tabBar()

      if store.isLoading {
        ContentActivitySkeletonView()
      } else {
        content()
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
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
    .overlay(alignment: .bottom) {
      Rectangle().fill(.neutral200).frame(height: 1)
    }
  }

  @ViewBuilder
  func tabButton(_ tab: ContentActivityType) -> some View {
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
              .pretendardFont(family: .Medium, size: 14)
              .foregroundStyle(.gray500)
              .lineLimit(1)

            if !item.stanceText.isEmpty {
              Text(item.stanceText)
                .pretendardFont(family: .Medium, size: 12)
                .foregroundStyle(.primary500)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
            }
          }

          Text(item.createdAt.relativeKoreanString)
            .pretendardFont(family: .SemiBold, size: 10)
            .foregroundStyle(.gray300)
        }

        Spacer(minLength: 0)
      }

      Text(item.content)
        .pretendardFont(family: .Regular, size: 13)
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
          .pretendardFont(family: .Medium, size: 12)
          .foregroundStyle(.gray300)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.beige600, lineWidth: 1)
    )
  }

  @ViewBuilder
  func avatar(_ author: ContentActivityAuthor) -> some View {
    if let url = URL(string: author.characterImageURL), !author.characterImageURL.isEmpty {
      KFImage(url)
        .resizable()
        .scaledToFill()
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    } else {
      ZStack {
        Circle().fill(.beige600)
        Image(systemName: "cat.fill")
          .font(.system(size: 16))
          .foregroundStyle(.gray300)
      }
      .frame(width: 36, height: 36)
    }
  }
}
