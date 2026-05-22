//
//  CommentReplyView.swift
//  Chat
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

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
        VStack(spacing: 0) {
          parentCommentSection()
          replySection()
        }
        .padding(.bottom, 16)
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
        author: store.parentComment.author,
        timeAgo: store.parentComment.timeAgo,
        option: store.parentComment.option,
        content: store.parentComment.content,
        replyCount: store.parentComment.replyCount,
        likeCount: store.parentComment.likeCount,
        isLiked: store.parentComment.isLiked,
        background: .beige50,
        showsReplyCount: true,
        likeAction: { send(.parentLikeTapped) }
      )
    }
    .padding(12)
    .background(.beige50)
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
          author: reply.author,
          timeAgo: reply.timeAgo,
          option: reply.option,
          content: reply.content,
          replyCount: nil,
          likeCount: reply.likeCount,
          isLiked: reply.isLiked,
          background: .beige50,
          showsReplyCount: false,
          likeAction: { send(.replyLikeTapped(reply.id)) }
        )
      }
    }
    .padding(.bottom, 24)
    .background(.beige50)
  }

  func commentCard(
    author: String,
    timeAgo: String,
    option: CommentOption,
    content: String,
    replyCount: Int?,
    likeCount: Int,
    isLiked: Bool,
    background: Color,
    showsReplyCount: Bool,
    likeAction: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(author: author, timeAgo: timeAgo, option: option)

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
            text: formattedCount(likeCount)
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
    timeAgo: String,
    option: CommentOption
  ) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Circle()
        .fill(.beige600)
        .frame(width: 36, height: 36)
        .overlay {
          Text(String(author.prefix(1)))
            .pretendardFont(family: .SemiBold, size: 13)
            .foregroundStyle(.primary500)
        }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(author)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.neutral500)
            .lineLimit(1)

          Text(timeAgo)
            .pretendardFont(family: .SemiBold, size: 10)
            .foregroundStyle(.neutral300)
        }

        optionBadge(option)
      }

      Spacer()

      Image(systemName: "ellipsis")
        .font(.system(size: 18, weight: .regular))
        .frame(width: 24, height: 24)
        .foregroundStyle(.neutral300)
    }
  }

  func optionBadge(_ option: CommentOption) -> some View {
    Text(option.label == "A" ? "변기는 변기다" : "예술이다")
      .pretendardFont(family: .Medium, size: 12)
      .foregroundStyle(option == .a ? .primary500 : .beige50)
      .padding(.horizontal, option == .a ? 4 : 6)
      .padding(.vertical, 2)
      .background(option == .a ? Color.beige600 : Color.primary500, in: RoundedRectangle(cornerRadius: 2))
  }

  func actionLabel(systemName: String, text: String) -> some View {
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

// MARK: - Format

private extension CommentReplyView {
  func formattedCount(_ count: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
  }
}
