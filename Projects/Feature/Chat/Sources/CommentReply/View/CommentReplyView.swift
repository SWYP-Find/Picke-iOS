//
//  CommentReplyView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import CommentDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import PickeCoreUtility

@ViewAction(for: CommentReplyFeature.self)
public struct CommentReplyView: View {
  private enum EditingTarget: Equatable {
    case parent
    case reply(Int)
  }

  @Bindable public var store: StoreOf<CommentReplyFeature>
  @FocusState private var isReplyFocused: Bool
  /// 딥링크 타깃 답글로 1회만 스크롤.
  @State private var didScrollToTarget = false

  private var editingTarget: EditingTarget? {
    if store.editingParent { return .parent }
    if let id = store.editingCommentId { return .reply(id) }
    return nil
  }

  public init(store: StoreOf<CommentReplyFeature>) {
    self.store = store
  }

  /// targetCommentId 와 일치하는 답글로 스크롤(1회).
  private func scrollToTargetReply(using proxy: ScrollViewProxy) {
    guard !didScrollToTarget,
          let targetId = store.targetCommentId,
          let reply = store.replies.first(where: { $0.commentId == targetId })
    else { return }
    didScrollToTarget = true
    withAnimation(.easeInOut(duration: 0.25)) {
      proxy.scrollTo(reply.id, anchor: .center)
    }
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      content()
      inputBar
    }
    .background(.bgBeige)
    .contentShape(Rectangle())
    .onTapGesture {
      isReplyFocused = false
    }
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onChange(of: editingTarget) { _, target in
      isReplyFocused = target != nil
    }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .animation(.easeInOut(duration: 0.18), value: store.menuTargetReplyId)
    .animation(.easeInOut(duration: 0.18), value: store.parentMenuOpen)
  }
}

// MARK: - Navigation

private extension CommentReplyView {
  /// Android PickeTopAppBar — "댓글" 가운데, 16 SemiBold textDefault, 배경 backgroundBeige.
  func navigationBar() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: "댓글"
    )
    .foregroundStyle(.textDefault)
    .background(.bgBeige)
  }
}

// MARK: - Content

private extension CommentReplyView {
  /// Android CommentScreen — 로딩 중 스켈레톤, 실패 시 PickeLoadFailedSection,
  /// 그 밖에는 원본 관점과 "답글 N개" 헤더를 고정하고 아래 답글 목록만 스크롤한다.
  @ViewBuilder
  func content() -> some View {
    if store.loadFailed {
      PickeLoadFailedSection()
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
    } else if store.isLoadingReplies, store.replies.isEmpty {
      ScrollView {
        CommentReplySkeletonView()
      }
      .scrollIndicators(.hidden)
      .frame(maxHeight: .infinity)
    } else {
      VStack(spacing: 0) {
        parentCard
        replyCountHeader
        replyScroll
      }
    }
  }

  var parentCard: some View {
    commentCard(
      CommentCardContent(
        author: store.parentComment.isMine ? "나" : store.parentComment.author,
        imageURL: store.parentComment.authorImageURL,
        timeAgo: store.parentComment.timeAgo,
        stance: store.parentComment.optionLabel ?? store.parentComment.option.label,
        content: store.parentComment.content,
        likeCount: store.parentComment.likeCount,
        isLiked: store.parentComment.isLiked,
        replyCount: store.parentComment.replyCount
      ),
      menuItems: parentMenuItems,
      isMenuOpen: store.parentMenuOpen,
      opensUpward: false,
      onMore: { send(.parentMenu(.more)) },
      onLike: { send(.parentLikeTapped) }
    )
    .zIndex(1)
  }

  /// Android CommentHeaderSection — 가로 16·세로 12, 13 SemiBold gray600.
  /// 배경 F9F8F6 은 토큰이 없어 가장 가까운 surfaceBeigeSubtle(F9F7F2)을 쓴다.
  var replyCountHeader: some View {
    Text("답글 \(store.replies.count)개")
      .pretendardFont(.semiBold13)
      .foregroundStyle(.gray600)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.surfaceBeigeSubtle)
  }

  var replyScroll: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(store.replies) { reply in
            commentCard(
              CommentCardContent(
                author: reply.isMine ? "나" : reply.author,
                imageURL: reply.authorImageURL,
                timeAgo: reply.timeAgo,
                stance: reply.stance.isEmpty ? reply.option.label : reply.stance,
                content: reply.content,
                likeCount: reply.likeCount,
                isLiked: reply.isLiked,
                replyCount: nil
              ),
              menuItems: replyMenuItems(for: reply),
              isMenuOpen: store.menuTargetReplyId == reply.id,
              opensUpward: reply.id == store.replies.last?.id && store.replies.count > 1,
              onMore: { send(.replyMenu(id: reply.id, action: .more)) },
              onLike: { send(.replyLikeTapped(reply.id)) }
            )
            .zIndex(store.menuTargetReplyId == reply.id ? 1 : 0)
            .id(reply.id)
          }
        }
      }
      .scrollIndicators(.hidden)
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: store.replies.count) { _, _ in
        scrollToTargetReply(using: proxy)
      }
    }
  }
}

// MARK: - Card

/// Android PickeCommentCard 에 넘기는 값 묶음.
private struct CommentCardContent {
  let author: String
  let imageURL: String?
  let timeAgo: String
  let stance: String
  let content: String
  let likeCount: Int
  let isLiked: Bool
  let replyCount: Int?
}

private extension CommentReplyView {
  /// Android PickeCommentCard(CommentItemCard) — surfaceBeigeDefault, 가로 16·세로 12, 간격 8, 아래 1 borderBeigeDefault.
  /// 헤더 [아바타 36][닉네임 12 SemiBold / 시간 10 SemiBold][배지], 본문 13 Regular textBody 전체,
  /// 액션 [좋아요][답글 수(원본만)] … [ic_more 24]. "…" 메뉴는 버튼 위로 펼친다.
  func commentCard(
    _ card: CommentCardContent,
    menuItems: [PickeMoreMenuItem],
    isMenuOpen: Bool,
    opensUpward: Bool,
    onMore: @escaping () -> Void,
    onLike: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      cardHeader(card)
      Text(card.content)
        .pretendardFont(.regular13, lineSpacingMultiple: 1.4)
        .foregroundStyle(.textBody)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 2)
      cardActions(
        card,
        menuItems: isMenuOpen ? menuItems : [],
        opensUpward: opensUpward,
        onMore: onMore,
        onLike: onLike
      )
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
  func cardHeader(_ card: CommentCardContent) -> some View {
    HStack(spacing: 8) {
      PickeAvatarView(
        imageURL: card.imageURL,
        fallback: card.author,
        size: 36
      )
      VStack(alignment: .leading, spacing: 0) {
        Text(card.author)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.textDefault)
          .lineLimit(1)
          .truncationMode(.tail)
        Text(card.timeAgo)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.textMuted)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Text(card.stance)
        .pickeBadge()
    }
  }

  @ViewBuilder
  func cardActions(
    _ card: CommentCardContent,
    menuItems: [PickeMoreMenuItem],
    opensUpward: Bool,
    onMore: @escaping () -> Void,
    onLike: @escaping () -> Void
  ) -> some View {
    HStack(spacing: 8) {
      Button(action: onLike) {
        iconCount(
          .heartPlus,
          count: card.likeCount
        )
        .foregroundStyle(card.isLiked ? .primary500 : .textMuted)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("좋아요")

      if let replyCount = card.replyCount {
        iconCount(
          .commentMessage,
          count: replyCount
        )
        .foregroundStyle(.textMuted)
        .accessibilityLabel("답글")
      }

      Spacer(minLength: 0)

      Button(action: onMore) {
        Image(asset: .more)
          .renderingMode(.template)
          .resizable()
          .frame(width: 24, height: 24)
          .foregroundStyle(.textMuted)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("더보기")
      .overlay(alignment: opensUpward ? .bottomTrailing : .topTrailing) {
        // Android DropdownMenu — "…" 버튼 바로 밑에서 펼치고, 아래 자리가 없으면(마지막 항목) 위로 펼친다.
        if !menuItems.isEmpty {
          PickeMoreMenuView(items: menuItems)
            .fixedSize()
            .offset(y: opensUpward ? -24 : 24)
            .transition(.opacity)
        }
      }
    }
  }

  /// Android PickeIconCount — 아이콘 16 + 12 Medium, 간격 2.
  func iconCount(
    _ icon: ImageAsset,
    count: Int
  ) -> some View {
    HStack(spacing: 2) {
      Image(asset: icon)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      Text(count.decimalFormatted)
        .pretendardFont(.labelSmall)
    }
  }
}

// MARK: - Menu

private extension CommentReplyView {
  /// Android commentMenuItems — 내 글 [삭제, 수정], 남의 글 [신고].
  var parentMenuItems: [PickeMoreMenuItem] {
    if store.parentComment.isMine {
      return [
        .delete { send(.parentMenu(.delete)) },
        .edit {
          send(.parentMenu(.edit))
          isReplyFocused = true
        },
      ]
    }
    return [.report { send(.parentMenu(.report)) }]
  }

  func replyMenuItems(for reply: CommentReplyItem) -> [PickeMoreMenuItem] {
    if reply.isMine {
      return [
        .delete { send(.replyMenu(id: reply.id, action: .delete)) },
        .edit {
          guard reply.commentId != nil else { return }
          send(.replyMenu(id: reply.id, action: .edit))
          isReplyFocused = true
        },
      ]
    }
    return [.report { send(.replyMenu(id: reply.id, action: .report)) }]
  }
}

// MARK: - Input

private extension CommentReplyView {
  private var inputBar: some View {
    PickeCommentInputBar(
      text: $store.replyText,
      focus: $isReplyFocused,
      placeholder: store.inputPlaceholder,
      isSendEnabled: store.isSendEnabled,
      onSend: {
        isReplyFocused = false
        send(.sendTapped)
      }
    )
  }
}
