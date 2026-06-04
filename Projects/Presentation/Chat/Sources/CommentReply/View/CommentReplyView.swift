//
//  CommentReplyView.swift
//  Chat
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Utill

@ViewAction(for: CommentReplyFeature.self)
public struct CommentReplyView: View {
  @Bindable public var store: StoreOf<CommentReplyFeature>
  @FocusState private var isReplyFocused: Bool

  public init(store: StoreOf<CommentReplyFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      ScrollView(showsIndicators: false) {
        if store.isLoadingReplies, store.replies.isEmpty {
          CommentReplySkeletonView()
        } else {
          VStack(spacing: 0) {
            parentCommentSection()
            replySection()
          }
          .padding(.bottom, 16)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      inputBar()
    }
    .background(Color.beige200.ignoresSafeArea())
    .contentShape(Rectangle())
    .onTapGesture {
      isReplyFocused = false
    }
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .animation(.easeInOut(duration: 0.18), value: store.menuTargetReplyId)
  }

  /// 답글 "…" 메뉴 (내 글: 수정/삭제, 남 글: 신고) — pill 형태.
  @ViewBuilder
  private func replyMenu(for reply: CommentReplyItem) -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      if reply.isMine {
        menuPill(title: "수정", systemImage: "pencil") { send(.replyMenu(id: reply.id, action: .edit)) }
        menuPill(title: "삭제", systemImage: "trash") { send(.replyMenu(id: reply.id, action: .delete)) }
      } else {
        menuPill(title: "신고", systemImage: "light.beacon.max.fill") { send(.replyMenu(id: reply.id, action: .report)) }
      }
    }
  }

  /// 부모(관점) "…" 메뉴 (내 글: 수정/삭제, 남 글: 신고).
  @ViewBuilder
  private func parentMenuView() -> some View {
    VStack(alignment: .trailing, spacing: 8) {
      if store.parentComment.isMine {
        menuPill(title: "수정", systemImage: "pencil") { send(.parentMenu(.edit)) }
        menuPill(title: "삭제", systemImage: "trash") { send(.parentMenu(.delete)) }
      } else {
        menuPill(title: "신고", systemImage: "light.beacon.max.fill") { send(.parentMenu(.report)) }
      }
    }
  }

  @ViewBuilder
  private func menuPill(
    title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: systemImage)
          .font(.system(size: 13, weight: .medium))
        Text(title)
          .pretendardFont(family: .Medium, size: 13)
      }
      .foregroundStyle(Color.beige50)
      .padding(.horizontal, 14)
      .padding(.vertical, 7)
      .background(Color.primary500, in: Capsule())
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Navigation

private extension CommentReplyView {
  @ViewBuilder
  func navigationBar() -> some View {
    HStack {
      Button { send(.backButtonTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .regular))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)

      Spacer()

      Text("댓글")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.neutral500)

      Spacer()

      Color.clear.frame(width: 24, height: 24)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .foregroundStyle(.neutral500)
    .background(.beige50)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }
}

// MARK: - Content

private extension CommentReplyView {
  @ViewBuilder
  func parentCommentSection() -> some View {
    VStack(spacing: 0) {
      commentCard(
        author: store.parentComment.isMine ? "나" : store.parentComment.author,
        imageURL: store.parentComment.authorImageURL,
        timeAgo: store.parentComment.timeAgo,
        option: store.parentComment.option,
        optionLabel: store.parentComment.optionLabel ?? "",
        content: store.parentComment.content,
        replyCount: store.parentComment.replyCount,
        likeCount: store.parentComment.likeCount,
        isLiked: store.parentComment.isLiked,
        isMine: store.parentComment.isMine,
        background: .beige50,
        showsReplyCount: true,
        moreAction: { send(.parentMenu(.more)) },
        likeAction: { send(.parentLikeTapped) }
      )
      .overlay(alignment: .topTrailing) {
        if store.parentMenuOpen {
          parentMenuView()
            .padding(.trailing, 12)
            .offset(y: 46)
            .zIndex(1)
        }
      }
    }
    .padding(12)
    .background(.beige50)
    .zIndex(store.parentMenuOpen ? 1 : 0)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }

  @ViewBuilder
  func replySection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("답글 \(store.replies.count)개")
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.neutral900)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 12)

      ForEach(store.replies) { reply in
        commentCard(
          author: reply.isMine ? "나" : reply.author,
          imageURL: reply.authorImageURL,
          timeAgo: reply.timeAgo,
          option: reply.option,
          optionLabel: store.parentComment.optionLabel ?? "",
          content: reply.content,
          replyCount: nil,
          likeCount: reply.likeCount,
          isLiked: reply.isLiked,
          isMine: reply.isMine,
          background: .beige50,
          showsReplyCount: false,
          moreAction: { send(.replyMenu(id: reply.id, action: .more)) },
          likeAction: { send(.replyLikeTapped(reply.id)) }
        )
        .overlay(alignment: .topTrailing) {
          if store.menuTargetReplyId == reply.id {
            replyMenu(for: reply)
              .padding(.trailing, 24)
              .offset(y: 46)
              .zIndex(1)
          }
        }
        .zIndex(store.menuTargetReplyId == reply.id ? 1 : 0)
      }
    }
    .padding(.bottom, 24)
    .background(.beige50)
  }

  func commentCard(
    author: String,
    imageURL: String?,
    timeAgo: String,
    option: CommentOption,
    optionLabel: String,
    content: String,
    replyCount: Int?,
    likeCount: Int,
    isLiked: Bool,
    isMine: Bool,
    background: Color,
    showsReplyCount: Bool,
    moreAction: (() -> Void)? = nil,
    likeAction: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(
        author: author,
        imageURL: imageURL,
        timeAgo: timeAgo,
        option: option,
        optionLabel: optionLabel,
        isMine: isMine,
        moreAction: moreAction
      )

      Text(content)
        .pretendardFont(family: .Regular, size: 13)
        .foregroundStyle(.neutral400)
        .lineSpacing(13 * 0.4)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 2)

      HStack(spacing: 12) {
        Spacer()

        if showsReplyCount, let replyCount {
          actionLabel(systemName: "message", text: "\(replyCount)")
        }

        Button(action: likeAction) {
          actionLabel(
            systemName: isLiked ? "heart.fill" : "heart",
            text: likeCount.decimalFormatted
          )
        }
        .buttonStyle(.plain)
      }
      .foregroundStyle(.neutral300)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(background, in: RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .stroke(.beige600, lineWidth: 1)
    }
    .padding(.horizontal, 12)
  }

  func commentHeader(
    author: String,
    imageURL: String?,
    timeAgo: String,
    option: CommentOption,
    optionLabel: String,
    isMine: Bool,
    moreAction: (() -> Void)?
  ) -> some View {
    HStack(alignment: .top, spacing: 8) {
      CommentAvatarView(
        imageURL: imageURL,
        fallback: author,
        size: 36
      )

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(author)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.neutral500)
            .lineLimit(1)

          if isMine {
            myBadge()
          }

          Text(timeAgo)
            .pretendardFont(family: .SemiBold, size: 10)
            .foregroundStyle(.neutral300)
        }

        optionBadge(label: optionLabel, option: option)
      }

      Spacer()

      Button { moreAction?() } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(.neutral300)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  func myBadge() -> some View {
    Text("나")
      .pretendardFont(family: .SemiBold, size: 10)
      .foregroundStyle(.beige50)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(.primary500, in: RoundedRectangle(cornerRadius: 2))
  }

  func optionBadge(label: String, option: CommentOption) -> some View {
    Text(label)
      .pretendardFont(family: .Medium, size: 12)
      .foregroundStyle(option == .a ? .primary500 : .beige50)
      .padding(.horizontal, option == .a ? 4 : 6)
      .padding(.vertical, 2)
      .background(option == .a ? .beige600 : .primary500, in: RoundedRectangle(cornerRadius: 2))
  }

  func actionLabel(
    systemName: String,
    text: String
  ) -> some View {
    HStack(spacing: 4) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 16, height: 16)

      Text(text)
        .pretendardFont(family: .Medium, size: 12)
    }
  }
}

// MARK: - Input

private extension CommentReplyView {
  @ViewBuilder
  func inputBar() -> some View {
    HStack(alignment: .bottom, spacing: 8) {
      VStack(alignment: .leading, spacing: 6) {
        TextField("내 의견은 어쩌구 저쩌구", text: $store.replyText, axis: .vertical)
          .pretendardFont(family: .Regular, size: 13)
          .foregroundStyle(.neutral400)
          .lineLimit(1 ... 3)
          .focused($isReplyFocused)

        Text("\(store.replyText.count)/200")
          .pretendardFont(family: .SemiBold, size: 10)
          .foregroundStyle(.neutral400)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .background(.beige50)

      Button { send(.sendTapped) } label: {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.beige50)
          .frame(width: 36, height: 36)
          .background(store.isSendEnabled ? Color.primary500 : Color.primary200, in: Circle())
      }
      .buttonStyle(.plain)
      .disabled(!store.isSendEnabled)
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 24)
    .frame(height: 128)
    .background(.beige400)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.beige800)
        .frame(height: 1)
    }
  }
}
