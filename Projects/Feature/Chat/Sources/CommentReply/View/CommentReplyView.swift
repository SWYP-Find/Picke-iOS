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
      replyScroll
      inputBar
    }
    .screenBackground()
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
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .animation(.easeInOut(duration: 0.18), value: store.menuTargetReplyId)
  }
}

private extension CommentReplyView {
  var replyScroll: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if store.isLoadingReplies, store.replies.isEmpty {
          CommentReplySkeletonView()
        } else {
          VStack(spacing: 0) {
            parentCommentSection()
            replyCountHeader()
            replySection()
          }
        }
      }
      .scrollIndicators(.hidden)
      .scrollDismissesKeyboard(.interactively)
      .onChange(of: store.replies.count) { _, _ in
        scrollToTargetReply(using: proxy)
      }
      .onChange(of: store.menuTargetReplyId) { _, id in
        guard let id else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
          proxy.scrollTo("reply-menu-\(id)", anchor: nil)
        }
      }
      .onChange(of: store.parentMenuOpen) { _, isOpen in
        guard isOpen else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
          proxy.scrollTo("parent-menu", anchor: nil)
        }
      }
    }
  }

  /// 답글 "…" 메뉴 (내 글: 수정/삭제, 남 글: 신고) — pill 형태.
  @ViewBuilder
  func replyMenu(for reply: CommentReplyItem) -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      if reply.isMine {
        PickeActionPill(title: "수정", systemImage: "pencil") {
          guard reply.commentId != nil else { return }
          send(.replyMenu(id: reply.id, action: .edit))
          isReplyFocused = true
        }
        PickeActionPill(title: "삭제", systemImage: "trash") { send(.replyMenu(id: reply.id, action: .delete)) }
      } else {
        PickeActionPill(title: "신고", systemImage: "light.beacon.max.fill") { send(.replyMenu(
          id: reply.id,
          action: .report
        )) }
      }
    }
  }

  /// 부모(관점) "…" 메뉴 (내 글: 수정/삭제, 남 글: 신고).
  @ViewBuilder
  func parentMenuView() -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      if store.parentComment.isMine {
        PickeActionPill(title: "수정", systemImage: "pencil") {
          send(.parentMenu(.edit))
          isReplyFocused = true
        }
        PickeActionPill(title: "삭제", systemImage: "trash") { send(.parentMenu(.delete)) }
      } else {
        PickeActionPill(title: "신고", systemImage: "light.beacon.max.fill") { send(.parentMenu(.report)) }
      }
    }
  }
}

// MARK: - Navigation

private extension CommentReplyView {
  @ViewBuilder
  func navigationBar() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      leadingTitle: "댓글"
    )
    .foregroundStyle(.gray500)
    // Figma: 앱바는 beige200 위에 투명 배치, 하단 구분선 없음
    .background(.beige200)
  }
}

// MARK: - Content

private extension CommentReplyView {
  @ViewBuilder
  func parentCommentSection() -> some View {
    // Figma: 원본 댓글은 beige50 풀폭 행, 상·하단 구분선(beige600)
    VStack(spacing: 0) {
      commentCard(
        author: store.parentComment.isMine ? "나" : store.parentComment.author,
        imageURL: store.parentComment.authorImageURL,
        timeAgo: store.parentComment.timeAgo,
        option: store.parentComment.option,
        content: store.parentComment.content,
        replyCount: store.parentComment.replyCount,
        likeCount: store.parentComment.likeCount,
        isLiked: store.parentComment.isLiked,
        showsReplyCount: true,
        moreAction: { send(.parentMenu(.more)) },
        likeAction: { send(.parentLikeTapped) }
      )
      .topDivider(.beige600)

      if store.parentMenuOpen {
        parentMenuView()
          .padding(.trailing, 16)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .background(.beige50)
          .bottomDivider(.beige600)
          .id("parent-menu")
      }
    }
  }

  @ViewBuilder
  func replyCountHeader() -> some View {
    // Figma: "답글 N개" 헤더 — beige200 배경, 하단 구분선, gray800 SemiBold 13
    Text("답글 \(store.replies.count)개")
      .pretendardFont(.semiBold13)
      .foregroundStyle(.gray800)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 18)
      .frame(height: 42)
      .background(.beige200)
      .bottomDivider(.beige600)
  }

  @ViewBuilder
  func replySection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(store.replies) { reply in
        VStack(spacing: 0) {
          commentCard(
            author: reply.isMine ? "나" : reply.author,
            imageURL: reply.authorImageURL,
            timeAgo: reply.timeAgo,
            option: reply.option,
            content: reply.content,
            replyCount: nil,
            likeCount: reply.likeCount,
            isLiked: reply.isLiked,
            showsReplyCount: false,
            moreAction: { send(.replyMenu(id: reply.id, action: .more)) },
            likeAction: { send(.replyLikeTapped(reply.id)) }
          )

          if store.menuTargetReplyId == reply.id {
            replyMenu(for: reply)
              .padding(.trailing, 16)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .background(.beige50)
              .bottomDivider(.beige600)
              .id("reply-menu-\(reply.id)")
          }
        }
        .id(reply.id)
      }
    }
  }

  @ViewBuilder
  func commentCard(
    author: String,
    imageURL: String?,
    timeAgo: String,
    option: CommentOption,
    content: String,
    replyCount: Int?,
    likeCount: Int,
    isLiked: Bool,
    showsReplyCount: Bool,
    moreAction: (() -> Void)? = nil,
    likeAction: @escaping () -> Void
  ) -> some View {
    // Figma: 댓글/답글은 beige50 풀폭 행 + 하단 구분선(beige600), 내부 카드 박스 없음
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(
        author: author,
        imageURL: imageURL,
        timeAgo: timeAgo,
        option: option,
        moreAction: moreAction
      )

      Text(content)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray400)
        .lineSpacing(13 * 0.4)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 2)

      HStack(spacing: 11) {
        Spacer()

        if showsReplyCount, let replyCount {
          actionLabel(systemName: "message", text: "\(replyCount)")
        }

        Button(action: likeAction) {
          HStack(spacing: 2) {
            Image(asset: .heartPlus)
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)
            Text(likeCount.decimalFormatted)
              .pretendardFont(.labelSmall)
          }
          .foregroundStyle(isLiked ? .primary500 : .gray300)
        }
        .buttonStyle(.plain)
      }
      .foregroundStyle(.gray300)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50)
    .bottomDivider(.beige600)
  }

  @ViewBuilder
  func commentHeader(
    author: String,
    imageURL: String?,
    timeAgo: String,
    option: CommentOption,
    moreAction: (() -> Void)?
  ) -> some View {
    HStack(spacing: 8) {
      PickeAvatarView(
        imageURL: imageURL,
        fallback: author,
        size: 36
      )

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(author)
            .pretendardFont(.semiBold12)
            .foregroundStyle(.gray500)
            .lineLimit(1)

          optionBadge(label: option.label, option: option)
        }

        // 시간 — caption/sm/semibold Pretendard SemiBold 10, gray300
        Text(timeAgo)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.gray300)
      }

      Spacer()

      if let moreAction {
        Button(action: moreAction) {
          Image(systemName: "ellipsis")
            .pretendardFont(family: .Regular, size: 18)
            .foregroundStyle(.gray300)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("더보기")
      }
    }
  }

  func optionBadge(
    label: String,
    option: CommentOption
  ) -> some View {
    Text(label)
      .pretendardFont(.labelSmall)
      .foregroundStyle(option == .a ? .primary500 : .beige50)
      .padding(.horizontal, option == .a ? 4 : 6)
      .padding(.vertical, 2)
      .roundedBackground(option == .a ? .beige600 : .primary500)
  }

  func actionLabel(
    systemName: String,
    text: String
  ) -> some View {
    // Figma like/more 칩: 아이콘 16 + 텍스트(Medium 12, gray300), 내부 gap 2, padding px6/py4
    HStack(spacing: 2) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 16, height: 16)

      Text(text)
        .pretendardFont(.labelSmall)
    }
  }
}

// MARK: - Input

private extension CommentReplyView {
  private var inputBar: some View {
    PickeCommentInputBar(
      text: $store.replyText,
      focus: $isReplyFocused,
      placeholder: "자유롭게 의견을 써주세요.",
      isSendEnabled: store.isSendEnabled,
      characterLimit: store.replyCharacterLimit,
      onSend: {
        isReplyFocused = false
        send(.sendTapped)
      }
    )
  }
}
