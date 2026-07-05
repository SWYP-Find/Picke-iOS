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
  /// 딥링크 타깃 답글로 1회만 스크롤.
  @State private var didScrollToTarget = false

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
      }
      inputBar()
    }
    .background(Color.beige200.ignoresSafeArea()) // Figma 화면 배경 beige200
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

      // 타이틀 "댓글" — heading/sm Pretendard SemiBold 16, gray500
      Text("댓글")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray500)

      Spacer()

      Color.clear.frame(width: 24, height: 24)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
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
      showsReplyCount: true,
      moreAction: { send(.parentMenu(.more)) },
      likeAction: { send(.parentLikeTapped) }
    )
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
    .overlay(alignment: .topTrailing) {
      if store.parentMenuOpen {
        parentMenuView()
          .padding(.trailing, 12)
          .offset(y: 46)
          .zIndex(1)
      }
    }
    .zIndex(store.parentMenuOpen ? 1 : 0)
  }

  @ViewBuilder
  func replyCountHeader() -> some View {
    // Figma: "답글 N개" 헤더 — beige200 배경, 하단 구분선, gray800 SemiBold 13
    Text("답글 \(store.replies.count)개")
      .pretendardFont(.semiBold13)
      .foregroundStyle(.gray800)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(.beige200)
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(.beige600)
          .frame(height: 1)
      }
  }

  @ViewBuilder
  func replySection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
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
        isMine: isMine,
        moreAction: moreAction
      )

      // Figma: 옵션 칩은 헤더 아래 독립 라인에 배치
      optionBadge(label: optionLabel, option: option)

      Text(content)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray400)
        .lineSpacing(13 * 0.4)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 2)

      HStack(spacing: 4) {
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
      .foregroundStyle(.gray300)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }

  func commentHeader(
    author: String,
    imageURL: String?,
    timeAgo: String,
    isMine: Bool,
    moreAction: (() -> Void)?
  ) -> some View {
    // Figma top 행: 아바타(36) + 이름/시간 스택 + 세로 더보기, 요소 간 gap 6
    HStack(spacing: 6) {
      CommentAvatarView(
        imageURL: imageURL,
        fallback: author,
        size: 36
      )

      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Text(author)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.gray500)
            .lineLimit(1)

          if isMine {
            myBadge()
          }
        }

        // 시간 — caption/sm/semibold Pretendard SemiBold 10, gray300
        Text(timeAgo)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.gray300)
      }

      Spacer()

      Button { moreAction?() } label: {
        // Figma: 세로 점 3개(더보기) 24pt
        Image(systemName: "ellipsis")
          .rotationEffect(.degrees(90))
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(.gray300)
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  func myBadge() -> some View {
    Text("나")
      .pretendardFont(.labelXSmall)
      .foregroundStyle(.beige50)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(.primary500, in: RoundedRectangle(cornerRadius: 2))
  }

  func optionBadge(label: String, option: CommentOption) -> some View {
    Text(label)
      .pretendardFont(.labelSmall)
      .foregroundStyle(option == .a ? .primary500 : .beige50)
      .padding(.horizontal, option == .a ? 4 : 6)
      .padding(.vertical, 2)
      .background(option == .a ? .beige600 : .primary500, in: RoundedRectangle(cornerRadius: 2))
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
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
  }
}

// MARK: - Input

private extension CommentReplyView {
  @ViewBuilder
  func inputBar() -> some View {
    HStack(alignment: .bottom, spacing: 8) {
      VStack(alignment: .leading, spacing: 6) {
        // Figma textarea: 텍스트/플레이스홀더 gray300, Pretendard Regular 13
        TextField("내 의견은 어쩌구 저쩌구", text: $store.replyText, axis: .vertical)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
          .lineLimit(1 ... 3)
          .focused($isReplyFocused)

        Text("\(store.replyText.count)/200")
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.gray300)
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
          .background(store.isSendEnabled ? .primary500 : .primary200, in: Circle())
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
    // Figma: 입력바 상단 그림자 0 -4 6 rgba(0,0,0,0.08)
    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: -4)
  }
}
