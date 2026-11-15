//
//  CommentView.swift
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
public struct CommentView: View {
  @Bindable public var store: StoreOf<CommentFeature>
  @FocusState private var isCommentFocused: Bool
  @State private var hasAnimatedVoteProgress = false

  public init(store: StoreOf<CommentFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      headerSection()
      if store.headerLoadFailed {
        // Android: 첫 조회 실패 시 통계·탭·목록 대신 실패 표시만 남는다.
        PickeLoadFailedSection()
          .padding(16)
          .frame(maxHeight: .infinity, alignment: .top)
      } else {
        commentScroll
      }
      inputBar()
    }
    .background(.bgBeige)
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
    .onChange(of: store.editingPerspectiveId) { _, editingID in
      isCommentFocused = editingID != nil
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
  }
}

private extension CommentView {
  @ViewBuilder
  func headerSection() -> some View {
    // Android PerspectiveScreen: 상단 바·통계·탭은 고정, 아래 목록만 스크롤한다. 배경 backgroundBeige.
    VStack(spacing: 0) {
      navigationBar
      if !store.headerLoadFailed {
        summarySection()
        filterTabs()
      }
    }
    .background(.bgBeige)
  }

  var commentScroll: some View {
    ScrollView(showsIndicators: false) {
      commentList()
    }
    .background(.bgBeige)
    .scrollDismissesKeyboard(.interactively)
    .simultaneousGesture(
      DragGesture(minimumDistance: 24)
        .onEnded { value in
          // 좌우 스와이프로 필터 탭(전체/옵션A/옵션B) 전환
          guard abs(value.translation.width) > abs(value.translation.height),
                abs(value.translation.width) > 50,
                let next = (value.translation.width < 0 ? store.nextFilter : store.previousFilter)
          else { return }
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            send(.filterTapped(next))
          }
        }
    )
  }

  func opensMenuUpward(_ comment: CommentItem) -> Bool {
    comment.id == store.comments.last?.id && store.comments.count > 1
  }

  /// "…" 버튼에서 펼치는 댓글 메뉴 — Android PickeMoreMenu.
  func inlineMenu(for comment: CommentItem) -> some View {
    PickeMoreMenuView(items: menuItems(for: comment))
  }

  /// "…" 메뉴 항목 — Android 순서: 내 글 삭제·수정, 남 글 신고.
  func menuItems(for comment: CommentItem) -> [PickeMoreMenuItem] {
    if comment.isMine {
      return [
        .delete { send(.commentMenu(id: comment.id, action: .delete)) },
        .edit { send(.commentMenu(id: comment.id, action: .edit)) },
      ]
    }
    return [.report { send(.commentMenu(id: comment.id, action: .report)) }]
  }
}

// MARK: - Navigation

private extension CommentView {
  var navigationBar: some View {
    // Android PickeTopAppBar — 제목(비면 "관점 남기기") 16 SemiBold textDefault, 오른쪽 다음(ic_arrow_right 16).
    // Android 는 시스템 뒤로 가기만 있어 앱바에 뒤로 버튼이 없지만, iOS 는 시스템 버튼이 없어 남긴다.
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: store.navigationTitle
    ) {
      Button { send(.forwardTapped) } label: {
        Image(asset: .arrowRight)
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("다음")
    }
    .foregroundStyle(.textDefault)
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
        rate: store.voteSummary.optionA.rateLabel
      )

      // Spacer 를 쓰면 컬럼이 남은 화면 높이를 전부 차지해 뱃지와 비율바가 벌어진다.
      // 고정 간격으로 묶어 양옆 옵션 컬럼 높이에 맞춘다.
      VStack(spacing: 0) {
        changeBadge()
        voteProgress()
          .padding(.horizontal, 8)
          .frame(height: 35)
      }
      .padding(.top, 10)
      .frame(maxWidth: .infinity)

      optionColumn(
        imageUrl: store.voteSummary.optionB.imageUrl,
        representative: store.voteSummary.optionB.representative,
        title: store.voteSummary.optionB.title,
        rate: store.voteSummary.optionB.rateLabel
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
    rate: String
  ) -> some View {
    VStack(spacing: 4) {
      avatarCircle(imageUrl: imageUrl, name: representative)

      VStack(spacing: 0) {
        Text(title)
          .pretendardFont(.medium11)
          .foregroundStyle(.textSubtler)
          .lineLimit(1)
        Text(rate)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.textSubtler)
      }
      .frame(maxWidth: .infinity)
    }
    .frame(width: 70)
  }

  @ViewBuilder
  func changeBadge() -> some View {
    // Android PerspectiveOpinionBadge — ic_think 16 + 12 SemiBold textPrimary, primary50 radius 2, 가로 4, 최소 높이 20.
    HStack(spacing: 2) {
      Image(asset: .think)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      Text(store.changeBadgeTitle)
        .pretendardFont(.semiBold12)
    }
    .foregroundStyle(.textPrimary)
    .padding(.horizontal, 4)
    .frame(minHeight: 20)
    .roundedBackground(.primary50)
  }

  @ViewBuilder
  func voteProgress() -> some View {
    GeometryReader { proxy in
      let leftWidth = proxy.size.width * store.voteSummary.optionA.percentage
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: .radiusDefault)
          .fill(.beige600)
          .frame(height: 6)
        RoundedRectangle(cornerRadius: .radiusDefault)
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
    LazyVStack(spacing: 0) {
      sortRow()
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)

      if store.isLoadingComments, store.comments.isEmpty {
        CommentSkeletonView()
          .padding(.horizontal, 16)
      } else if store.comments.isEmpty {
        emptyState()
      } else {
        ForEach(store.comments) { comment in
          commentCard(comment)
            .zIndex(store.menuTargetCommentID == comment.id ? 1 : 0)
            .onAppear {
              // Android: 마지막 항목이 보이면 다음 페이지(hasNext)를 부른다.
              if comment.id == store.comments.last?.id {
                send(.lastCommentAppeared)
              }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: store.menuTargetCommentID)

        if store.isLoadingComments {
          ProgressView()
            .tint(.primary900)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
      }
    }
  }

  @ViewBuilder
  func emptyState() -> some View {
    // Android PickeEmptyState(fillParentMaxSize) — 정렬 줄 아래 남은 높이 가운데.
    PickeEmptyStateView(message: store.emptyMessage)
      .containerRelativeFrame(.vertical) { height, _ in max(0, height - 60) }
  }

  @ViewBuilder
  func commentCard(_ comment: CommentItem) -> some View {
    // Android PickeCommentCard — surfaceBeigeDefault, 안쪽 가로 16·세로 12, 간격 8, 아래 1 구분선 borderBeigeDefault.
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(comment)

      VStack(alignment: .leading, spacing: 4) {
        commentBody(comment)
        detailLink(comment)
      }

      commentActions(comment)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    // 구분선은 내용 아래에 그려 펼친 메뉴를 가리지 않게 한다.
    .background(alignment: .bottom) {
      ZStack(alignment: .bottom) {
        Color.surfaceBeigeDefault
        PickeDivider(.borderBeigeDefault)
      }
    }
  }

  @ViewBuilder
  func commentBody(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      Text(comment.content)
        .pretendardFont(.regular13, lineSpacingMultiple: 1.4)
        .foregroundStyle(.textMuted)
        // Android CONTENT_MAX_LINES = 3. 전체 내용은 답글 화면에서 확인한다.
        .lineLimit(3)
        .truncationMode(.tail)
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
          .foregroundStyle(.textDefault)
          .lineLimit(1)
          .truncationMode(.tail)

        Text(comment.timeAgo)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.textMuted)
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
    // Android: 좋아요·답글 수는 왼쪽 간격 8, "…"(ic_more 24)는 오른쪽.
    HStack(spacing: 8) {
      likeButton(comment)
      replyCountButton(comment)
      Spacer(minLength: 0)
      moreButton(commentId: comment.id)
        .overlay(alignment: opensMenuUpward(comment) ? .bottomTrailing : .topTrailing) {
          // Android DropdownMenu — "…" 버튼 바로 밑에서 펼치고, 아래 자리가 없으면(마지막 항목) 위로 펼친다.
          if store.menuTargetCommentID == comment.id {
            inlineMenu(for: comment)
              .fixedSize()
              .offset(y: opensMenuUpward(comment) ? -24 : 24)
              .transition(.opacity)
          }
        }
    }
  }

  @ViewBuilder
  func moreButton(commentId: UUID) -> some View {
    Button { send(.commentMenu(id: commentId, action: .more)) } label: {
      Image(asset: .more)
        .renderingMode(.template)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundStyle(.textMuted)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func replyCountButton(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      HStack(spacing: 2) {
        Image(asset: .commentMessage)
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
        Text(comment.replyCount.decimalFormatted)
          .pretendardFont(.labelSmall)
      }
      .foregroundStyle(.textMuted)
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
      .foregroundStyle(comment.isLiked ? .primary500 : .textMuted)
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
    VStack(spacing: 0) {
      if store.isEditingComment {
        HStack {
          Spacer()
          Button("수정 취소") { send(.composeDismissed) }
            .pretendardFont(.labelSmall)
            .foregroundStyle(.gray500)
            .padding(12)
        }
        .background(.surfaceBeigeStrong)
      }
      PickeCommentInputBar(
        text: $store.commentText,
        focus: $isCommentFocused,
        placeholder: store.inputPlaceholder,
        isSendEnabled: store.isSendEnabled,
        isSubmitting: store.isSubmitting,
        isCompact: true,
        onSend: {
          isCommentFocused = false
          send(.sendTapped)
        }
      )
    }
  }
}

#Preview {
  CommentView(
    store: Store(initialState: CommentFeature.State()) {
      CommentFeature()
    }
  )
}
