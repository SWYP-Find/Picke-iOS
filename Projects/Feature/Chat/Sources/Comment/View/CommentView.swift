//
//  CommentView.swift
//  Chat
//

import SwiftUI

import CommentDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeCoreUtility

@ViewAction(for: CommentFeature.self)
public struct CommentView: View {
  @Bindable public var store: StoreOf<CommentFeature>
  @FocusState private var isCommentFocused: Bool
  @State private var hasAnimatedVoteProgress = false

  public init(store: StoreOf<CommentFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Figma 8661-8291: 네비바·투표요약·필터탭은 고정, 아래 List 영역만 스크롤한다.
      VStack(spacing: 4) {
        navigationBar()
        summarySection()
        filterTabs()
      }
      .background(.beige200)

      ScrollView(showsIndicators: false) {
        commentList()
      }
      .background(.surfaceBeigeDefault)
      .scrollDismissesKeyboard(.interactively)
      .simultaneousGesture(
        DragGesture(minimumDistance: 24)
          .onEnded { value in
            // 좌우 스와이프로 필터 탭(전체/옵션A/옵션B) 전환
            guard abs(value.translation.width) > abs(value.translation.height),
                  abs(value.translation.width) > 50,
                  let next = adjacentFilter(forward: value.translation.width < 0)
            else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              send(.filterTapped(next))
            }
          }
      )
      inputBar()
    }
    .screenBackground()
    .contentShape(Rectangle())
    .onTapGesture {
      isCommentFocused = false
    }
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear {
      send(.onAppear)
      withAnimation(.easeOut(duration: 0.75).delay(0.15)) {
        hasAnimatedVoteProgress = true
      }
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  /// 댓글 카드 바로 아래에 뜨는 인라인 메뉴 (pill 형태).
  @ViewBuilder
  private func inlineMenu(for comment: CommentItem) -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      ForEach(menuItems(for: comment)) { item in
        Button { item.action() } label: {
          HStack(spacing: 4) {
            Image(systemName: item.systemImage)
              .font(.system(size: 13, weight: .medium))
            Text(item.title)
              .pretendardFont(.medium13)
          }
          .foregroundStyle(.beige50)
          .padding(.horizontal, 14)
          .padding(.vertical, 7)
          .background(.primary500, in: Capsule())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.trailing, 4)
  }

  /// "…" 메뉴 항목 — 내 글: 수정/삭제, 남 글: 신고.
  private func menuItems(for comment: CommentItem) -> [BottomActionItem] {
    if comment.isMine {
      return [
        BottomActionItem(title: "수정", systemImage: "pencil") { send(.commentMenu(id: comment.id, action: .edit)) },
        BottomActionItem(title: "삭제", systemImage: "trash", isDestructive: true) { send(.commentMenu(
          id: comment.id,
          action: .delete
        )) },
      ]
    } else {
      return [
        BottomActionItem(title: "신고", systemImage: "light.beacon.max.fill", isDestructive: true) {
          send(.commentMenu(id: comment.id, action: .report))
        },
      ]
    }
  }

  /// 현재 선택된 필터 기준 인접 필터(스와이프 방향). 범위를 벗어나면 nil.
  private func adjacentFilter(forward: Bool) -> CommentFilter? {
    let all = CommentFilter.allCases
    guard let idx = all.firstIndex(of: store.selectedFilter) else { return nil }
    let nextIdx = forward ? idx + 1 : idx - 1
    guard all.indices.contains(nextIdx) else { return nil }
    return all[nextIdx]
  }
}

// MARK: - Navigation

private extension CommentView {
  @ViewBuilder
  func navigationBar() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: store.title
    ) {
      Button { send(.forwardTapped) } label: {
        Image(systemName: "chevron.right")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
    }
    .foregroundStyle(.cardBaseTextTitle)
  }
}

// MARK: - Summary

private extension CommentView {
  @ViewBuilder
  func summarySection() -> some View {
    // Figma 9331-7984: 양옆 옵션 컬럼 w70(아바타40/제목/퍼센트), 가운데 뱃지+비율바, px16 py4.
    HStack(alignment: .bottom, spacing: 0) {
      optionColumn(
        imageUrl: store.voteSummary.optionA.imageUrl,
        representative: store.voteSummary.optionA.representative,
        title: store.voteSummary.optionA.title,
        percentage: store.voteSummary.optionA.percentage
      )

      // Spacer 를 쓰면 컬럼이 남은 화면 높이를 전부 차지해 뱃지와 비율바가 벌어진다.
      // 고정 간격으로 묶어 양옆 옵션 컬럼 높이에 맞춘다.
      VStack(spacing: 24) {
        changeBadge()
        voteProgress()
          .padding(.horizontal, 8)
      }
      .padding(.top, 10)
      .frame(maxWidth: .infinity)

      optionColumn(
        imageUrl: store.voteSummary.optionB.imageUrl,
        representative: store.voteSummary.optionB.representative,
        title: store.voteSummary.optionB.title,
        percentage: store.voteSummary.optionB.percentage
      )
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  @ViewBuilder
  func optionColumn(
    imageUrl: String?,
    representative: String,
    title: String,
    percentage: Double
  ) -> some View {
    VStack(spacing: 4) {
      avatarCircle(imageUrl: imageUrl, name: representative)

      VStack(spacing: 0) {
        Text(title)
          .pretendardFont(.medium11)
          .foregroundStyle(.gray500)
          .lineLimit(1)
        Text(percentText(percentage))
          .pretendardFont(.semiBold12)
          .foregroundStyle(.gray500)
      }
      .frame(maxWidth: .infinity)
    }
    .frame(width: 70)
  }

  @ViewBuilder
  func changeBadge() -> some View {
    HStack(spacing: 4) {
      Image(systemName: "lightbulb")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.primary500)
      Text(store.changeBadgeTitle)
        .pretendardFont(.semiBold11)
        .foregroundStyle(.primary500)
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
    .roundedBackground(.primary50)
  }

  @ViewBuilder
  func voteProgress() -> some View {
    GeometryReader { proxy in
      let leftWidth = proxy.size.width * store.voteSummary.optionA.percentage
      ZStack(alignment: .leading) {
        Capsule()
          .fill(.beige600)
          .frame(height: 6)
        Capsule()
          .fill(.primary500)
          .frame(width: hasAnimatedVoteProgress ? max(0, leftWidth) : 0, height: 6)
      }
      .frame(maxHeight: .infinity)
      .animation(.easeOut(duration: 0.75), value: store.voteSummary.optionA.percentage)
    }
    .frame(height: 6)
  }

  @ViewBuilder
  func avatarCircle(imageUrl: String?, name: String) -> some View {
    PickeAvatarView(
      imageURL: imageUrl,
      fallback: name,
      size: 40
    )
  }
}

// MARK: - Filters

private extension CommentView {
  @ViewBuilder
  func filterTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(CommentFilter.allCases, id: \.self) { filter in
        filterButton(filter)
      }
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func sortRow() -> some View {
    HStack(spacing: 8) {
      sortButton(.popular)
      sortButton(.latest)
      Spacer()
    }
    .padding(.vertical, 4) // Figma 8661-8320: sort 행 py4
  }

  @ViewBuilder
  func filterButton(_ filter: CommentFilter) -> some View {
    let title: String = switch filter {
    case .all: "전체"
    case .optionA: store.voteSummary.optionA.title
    case .optionB: store.voteSummary.optionB.title
    }
    Button {
      send(.filterTapped(filter))
    } label: {
      Text(title)
        .pickeSegmentTab(isSelected: store.selectedFilter == filter)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func sortButton(_ sort: CommentSort) -> some View {
    Button {
      send(.sortTapped(sort))
    } label: {
      Text(sort.title)
        .pickeSortChip(isSelected: store.selectedSort == sort)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Comment List

private extension CommentView {
  @ViewBuilder
  func commentList() -> some View {
    // Figma 8661-8318: List 컨테이너 p16 / 댓글모음 gap6 pb24.
    VStack(spacing: 6) {
      sortRow()

      if store.isLoadingComments, store.comments.isEmpty {
        CommentSkeletonView()
      } else if store.comments.isEmpty {
        emptyState()
      } else {
        ForEach(store.comments) { comment in
          commentCard(comment)
            .overlay(alignment: .bottomTrailing) {
              if store.menuTargetCommentID == comment.id {
                inlineMenu(for: comment)
                  .offset(y: 34)
                  .zIndex(1)
              }
            }
            .zIndex(store.menuTargetCommentID == comment.id ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.18), value: store.menuTargetCommentID)
      }
    }
    .padding(16)
    .padding(.bottom, 24)
  }

  @ViewBuilder
  func emptyState() -> some View {
    PickeEmptyStateView(message: "아직 작성된 관점이 없습니다")
      .padding(.vertical, 60)
  }

  @ViewBuilder
  func commentCard(_ comment: CommentItem) -> some View {
    // Figma 8661-8331: 흰 배경 + 하단 구분선만, py12 / 내부 gap8.
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(comment)

      VStack(alignment: .leading, spacing: 4) {
        commentBody(comment)
        detailLink(comment)
      }

      commentActions(comment)
    }
    .pickeListRowCard()
  }

  @ViewBuilder
  func commentBody(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      Text(comment.content)
        .pretendardFont(.regular13)
        .foregroundStyle(.cardBaseTextBody)
        .lineSpacing(13 * 0.4)
        // 3줄 초과 시 … 줄임 — 전체 내용은 답글 화면에서 확인.
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func detailLink(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      Text("자세히 보기")
        .pretendardFont(.labelSmall)
        .foregroundStyle(.gray200)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func commentHeader(_ comment: CommentItem) -> some View {
    HStack(spacing: 8) {
      avatar(urlString: comment.authorImageURL, fallback: comment.author)

      VStack(alignment: .leading, spacing: 0) {
        Text(comment.isMine ? "나" : comment.author)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.cardBaseTextTitle)
          .lineLimit(1)

        Text(comment.timeAgo)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.cardBaseTextDecription)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      optionBadge(comment)
    }
  }

  @ViewBuilder
  func optionBadge(_ comment: CommentItem) -> some View {
    let summary = comment.option == .a ? store.voteSummary.optionA : store.voteSummary.optionB
    Text(comment.optionLabel ?? summary.title)
      .pickeBadge()
  }

  @ViewBuilder
  func commentActions(_ comment: CommentItem) -> some View {
    // Figma 8661-8352: 좋아요·답글수는 좌측 gap11, "…" 메뉴는 우측.
    HStack(spacing: 0) {
      HStack(spacing: 11) {
        likeButton(comment)
        replyCountButton(comment)
      }
      Spacer()
      moreButton(commentId: comment.id)
    }
  }

  @ViewBuilder
  func moreButton(commentId: UUID) -> some View {
    Button { send(.commentMenu(id: commentId, action: .more)) } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 18, weight: .regular))
        .foregroundStyle(.cardBaseTextDecription)
        .frame(width: 24, height: 24)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func replyCountButton(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      HStack(spacing: 2) {
        Image(systemName: "message")
          .font(.system(size: 14, weight: .medium))
          .frame(width: 16, height: 16)
        Text("\(comment.replyCount)")
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(.cardBaseTextDecription)
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func likeButton(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .like)) } label: {
      HStack(spacing: 2) {
        Image(asset: .heartPlus)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
        Text(comment.likeCount.decimalFormatted)
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(comment.isLiked ? .primary500 : .cardBaseTextDecription)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func avatar(
    urlString: String?,
    fallback: String
  ) -> some View {
    PickeAvatarView(
      imageURL: urlString,
      fallback: fallback,
      size: 36
    )
  }
}

// MARK: - Input

private extension CommentView {
  @ViewBuilder
  func inputBar() -> some View {
    PickeCommentInputBar(
      text: $store.commentText,
      focus: $isCommentFocused,
      placeholder: "댓글을 입력해주세요",
      isSendEnabled: store.isSendEnabled,
      onSend: { send(.sendTapped) }
    )
  }
}

// MARK: - Format

private extension CommentView {
  func percentText(_ percentage: Double) -> String {
    "\(String(format: "%.1f", percentage * 100))%"
  }
}

#Preview {
  CommentView(
    store: Store(initialState: CommentFeature.State()) {
      CommentFeature()
    }
  )
}
