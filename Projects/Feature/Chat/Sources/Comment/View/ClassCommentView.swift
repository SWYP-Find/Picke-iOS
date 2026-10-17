//
//  ClassCommentView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import CommentDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: CommentFeature.self)
public struct ClassCommentView: View {
  @Bindable public var store: StoreOf<CommentFeature>
  private let onOpenReport: (Int) -> Void
  @FocusState private var isCommentFocused: Bool
  @State private var hasAnimatedVoteProgress = false

  public init(
    store: StoreOf<CommentFeature>,
    onOpenReport: @escaping (Int) -> Void
  ) {
    self.store = store
    self.onOpenReport = onOpenReport
  }

  public var body: some View {
    VStack(spacing: 0) {
      headerSection()
      commentScroll()
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
    .onChange(of: store.editingPerspectiveId) { _, editingId in
      isCommentFocused = editingId != nil
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }

  @ViewBuilder
  private func headerSection() -> some View {
    VStack(spacing: 4) {
      navigationBar()
      summarySection()
      filterTabs()
    }
    .background(.beige200)
  }

  @ViewBuilder
  private func commentScroll() -> some View {
    ScrollView(showsIndicators: false) {
      commentList()
    }
    .background(.surfaceBeigeDefault)
    .scrollDismissesKeyboard(.interactively)
    .simultaneousGesture(
      DragGesture(minimumDistance: 24)
        .onEnded { value in
          guard abs(value.translation.width) > abs(value.translation.height),
                abs(value.translation.width) > 50,
                let next = adjacentFilter(forward: value.translation.width < 0)
          else { return }
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            send(.filterTapped(next))
          }
        }
    )
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

private extension ClassCommentView {
  @ViewBuilder
  func navigationBar() -> some View {
    PickeNavigationBar {
      Button { onOpenReport(store.battleId) } label: {
        HStack(spacing: 4) {
          Image(systemName: "doc.text")
            .font(.system(size: 14, weight: .regular))
          Text("리포트")
            .pretendardFont(.labelSmall)
        }
        .foregroundStyle(.primary500)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("리포트")
    }
    .overlay {
      Text(store.title)
        .pretendardFont(.headingMedium)
        .kerning(-0.4)
        .lineLimit(1)
        .truncationMode(.tail)
        .padding(.horizontal, 72)
        .allowsHitTesting(false)
    }
    .foregroundStyle(.cardBaseTextTitle)
  }
}

// MARK: - Summary

private extension ClassCommentView {
  @ViewBuilder
  func summarySection() -> some View {
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

private extension ClassCommentView {
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

private extension ClassCommentView {
  @ViewBuilder
  func commentList() -> some View {
    VStack(spacing: 0) {
      sortRow()
        .padding(.horizontal, 16)
        .padding(.bottom, 6)

      if store.isLoadingComments, store.comments.isEmpty {
        loadingComments()
          .padding(.horizontal, 16)
      } else if store.comments.isEmpty {
        emptyState()
          .padding(.horizontal, 16)
      } else {
        ForEach(store.comments) { comment in
          commentCard(comment)
            .overlay(alignment: .bottomTrailing) {
              if store.menuTargetCommentID == comment.id {
                inlineMenu(for: comment)
                  .padding(.bottom, 28)
                  .padding(.trailing, 16)
                  .zIndex(1)
              }
            }
            .zIndex(store.menuTargetCommentID == comment.id ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.18), value: store.menuTargetCommentID)
      }
    }
    .padding(.vertical, 16)
    .padding(.bottom, 24)
  }

  @ViewBuilder
  func emptyState() -> some View {
    PickeEmptyStateView(message: "아직 작성된 관점이 없습니다")
      .padding(.vertical, 60)
  }

  @ViewBuilder
  func loadingComments() -> some View {
    VStack(spacing: 12) {
      ForEach(0 ..< 3, id: \.self) { _ in
        SkeletonView(.round(cornerRadius: 6))
          .frame(height: 100)
      }
    }
  }

  @ViewBuilder
  func commentCard(_ comment: CommentItem) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(comment)

      VStack(alignment: .leading, spacing: 4) {
        commentBody(comment)
        detailLink(comment)
      }

      commentActions(comment)
    }
    .padding(.horizontal, 16)
    .pickeListRowCard()
  }

  @ViewBuilder
  func commentBody(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      Text(comment.content)
        .pretendardFont(.regular13)
        .foregroundStyle(.cardBaseTextBody)
        .lineSpacing(13 * 0.4)
        // 전체 내용은 답글 화면에서 확인한다.
        .lineLimit(2)
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

private extension ClassCommentView {
  @ViewBuilder
  func inputBar() -> some View {
    VStack(spacing: 0) {
      if store.editingPerspectiveId != nil {
        HStack {
          Spacer()
          Button { send(.composeDismissed) } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.gray500)
              .frame(width: 36, height: 32)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("댓글 수정 취소")
        }
        .padding(.horizontal, 12)
        .background(.surfaceBeigeStrong)
      }

      HStack(spacing: 8) {
        TextField("내 생각을 입력해보세요", text: $store.commentText, axis: .vertical)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray400)
          .lineLimit(1 ... 2)
          .focused($isCommentFocused)
          .frame(maxWidth: .infinity)

        Button { send(.sendTapped) } label: {
          Image(systemName: "paperplane.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.iconGrayInverse)
            .frame(width: 36, height: 36)
            .background(
              store.isSendEnabled ? .buttonIconBackgroundDefault : .buttonIconBackgroundDisabled,
              in: Circle()
            )
        }
        .buttonStyle(.plain)
        .disabled(!store.isSendEnabled)
      }
      .pickeTextField(height: 52)
      .padding(.horizontal, 16)
      .background(.surfaceBeigeStrong)
    }
  }
}

// MARK: - Format

private extension ClassCommentView {
  func percentText(_ percentage: Double) -> String {
    "\(String(format: "%.1f", percentage * 100))%"
  }
}
