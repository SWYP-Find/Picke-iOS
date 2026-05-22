//
//  CommentView.swift
//  Chat
//
//  .pen `댓글화면` 기준 mock 댓글 UI.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Kingfisher

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
      navigationBar()
      ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
          summarySection()
          filterSection()
          commentList()
        }
        .padding(.bottom, 16)
      }
      .scrollDismissesKeyboard(.interactively)
      inputBar()
    }
    .background(Color.beige200.ignoresSafeArea())
    .contentShape(Rectangle())
    .onTapGesture {
      isCommentFocused = false
    }
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear {
      send(.onAppear)
      withAnimation(.easeOut(duration: 0.75).delay(0.15)) {
        hasAnimatedVoteProgress = true
      }
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

// MARK: - Navigation

private extension CommentView {
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

      Text(store.title)
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.neutral500)
        .lineLimit(1)

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

// MARK: - Summary

private extension CommentView {
  @ViewBuilder
  func summarySection() -> some View {
    VStack(spacing: 12) {
      changeBadge()

      HStack(alignment: .center, spacing: 12) {
        voteSide(store.voteSummary.optionA, alignment: .leading)
        voteProgress()
        voteSide(store.voteSummary.optionB, alignment: .trailing)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(.beige50)
  }

  @ViewBuilder
  func changeBadge() -> some View {
    HStack {
      Text(store.voteSummary.changeBadgeTitle)
        .pretendardFont(family: .SemiBold, size: 11)
        .foregroundStyle(.primary500)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(.primary50, in: RoundedRectangle(cornerRadius: 2))
      Spacer()
    }
  }

  @ViewBuilder
  func voteSide(
    _ option: VoteOptionSummary,
    alignment: HorizontalAlignment
  ) -> some View {
    VStack(alignment: alignment, spacing: 6) {
      avatarLabel(option.representative)
      Text(percentText(option.percentage))
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral500)
    }
    .frame(width: 52, alignment: alignment == .leading ? .leading : .trailing)
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
  func avatarLabel(_ name: String) -> some View {
    VStack(spacing: 4) {
      Circle()
        .fill(.beige600)
        .frame(width: 40, height: 40)
        .overlay {
          Text(String(name.prefix(1)))
            .pretendardFont(family: .SemiBold, size: 14)
            .foregroundStyle(.primary500)
        }

      Text(name)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral500)
        .lineLimit(1)
    }
  }
}

// MARK: - Filters

private extension CommentView {
  @ViewBuilder
  func filterSection() -> some View {
    VStack(spacing: 12) {
      filterTabs()
      sortRow()
    }
    .padding(.top, 14)
    .padding(.bottom, 12)
  }

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
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func filterButton(_ filter: CommentFilter) -> some View {
    let isSelected = store.selectedFilter == filter
    let title: String = switch filter {
    case .all: "전체"
    case .optionA: store.voteSummary.optionA.title
    case .optionB: store.voteSummary.optionB.title
    }
    Button {
      send(.filterTapped(filter))
    } label: {
      Text(title)
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(isSelected ? .primary500 : .neutral300)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(isSelected ? Color.primary500 : Color.neutral200)
            .frame(height: isSelected ? 2.5 : 1)
        }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func sortButton(_ sort: CommentSort) -> some View {
    let isSelected = store.selectedSort == sort
    Button {
      send(.sortTapped(sort))
    } label: {
      Text(sort.title)
        .pretendardFont(family: .Medium, size: 13)
        .foregroundStyle(isSelected ? .beige50 : .primary500)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          isSelected ? Color.primary500 : Color.primary50,
          in: RoundedRectangle(cornerRadius: 2)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .stroke(Color.primary500, lineWidth: isSelected ? 0 : 1)
        }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Comment List

private extension CommentView {
  @ViewBuilder
  func commentList() -> some View {
    VStack(spacing: 12) {
      ForEach(store.filteredComments) { comment in
        commentCard(comment)
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 24)
  }

  @ViewBuilder
  func commentCard(_ comment: CommentItem) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      commentHeader(comment)
      commentBody(comment)
      commentActions(comment)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .stroke(.beige600, lineWidth: 1)
    }
  }

  @ViewBuilder
  func commentBody(_ comment: CommentItem) -> some View {
    Button { send(.replyTapped(comment.id)) } label: {
      Text(comment.content)
        .pretendardFont(family: .Regular, size: 13)
        .foregroundStyle(.neutral400)
        .lineSpacing(13 * 0.4)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func commentHeader(_ comment: CommentItem) -> some View {
    HStack(alignment: .top, spacing: 6) {
      avatar(urlString: comment.authorImageURL, fallback: comment.author)
      commentAuthorBlock(comment)
      Spacer()
      reportButton(commentId: comment.id)
    }
  }

  @ViewBuilder
  func commentAuthorBlock(_ comment: CommentItem) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Text(comment.author)
          .pretendardFont(family: .Medium, size: 14)
          .foregroundStyle(.neutral500)
          .lineLimit(1)

        Text(comment.timeAgo)
          .pretendardFont(family: .Medium, size: 12)
          .foregroundStyle(.neutral300)
      }

      optionBadge(comment)
    }
  }

  @ViewBuilder
  func reportButton(commentId: UUID) -> some View {
    Button { send(.reportButtonTapped(commentId)) } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 18, weight: .regular))
        .frame(width: 24, height: 24)
    }
    .buttonStyle(.plain)
    .foregroundStyle(.neutral300)
  }

  @ViewBuilder
  func optionBadge(_ comment: CommentItem) -> some View {
    let summary = comment.option == .a ? store.voteSummary.optionA : store.voteSummary.optionB
    let label = comment.optionLabel ?? summary.title
    Text(label)
      .pretendardFont(family: .Medium, size: 12)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func commentActions(_ comment: CommentItem) -> some View {
    HStack(spacing: 12) {
      moreButton(commentId: comment.id)
      Spacer()
      replyCountButton(comment)
      likeButton(comment)
    }
    .foregroundStyle(.neutral300)
  }

  @ViewBuilder
  func moreButton(commentId: UUID) -> some View {
    Button { send(.moreTapped(commentId)) } label: {
      Text("더보기")
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.neutral300)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func replyCountButton(_ comment: CommentItem) -> some View {
    Button { send(.replyTapped(comment.id)) } label: {
      actionLabel(systemName: "message", text: "\(comment.replyCount)")
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func likeButton(_ comment: CommentItem) -> some View {
    Button { send(.likeTapped(comment.id)) } label: {
      actionLabel(
        systemName: comment.isLiked ? "heart.fill" : "heart",
        text: formattedCount(comment.likeCount)
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func actionLabel(systemName: String, text: String) -> some View {
    HStack(spacing: 4) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 16, height: 16)
      Text(text)
        .pretendardFont(family: .Medium, size: 12)
    }
  }

  @ViewBuilder
  func avatar(urlString: String?, fallback: String) -> some View {
    if let urlString, let url = URL(string: urlString) {
      KFImage(url)
        .placeholder { Color.beige600 }
        .resizable()
        .scaledToFill()
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(Circle().stroke(.beige600, lineWidth: 1))
    } else {
      Circle()
        .fill(.beige600)
        .frame(width: 36, height: 36)
        .overlay {
          Text(String(fallback.prefix(1)))
            .pretendardFont(family: .SemiBold, size: 13)
            .foregroundStyle(.primary500)
        }
    }
  }
}

// MARK: - Input

private extension CommentView {
  @ViewBuilder
  func inputBar() -> some View {
    VStack(spacing: 8) {
      HStack(alignment: .bottom, spacing: 8) {
        inputTextBox()
        sendButton()
      }
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

  @ViewBuilder
  func inputTextBox() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      TextField("댓글을 입력해주세요", text: $store.commentText, axis: .vertical)
        .pretendardFont(family: .Regular, size: 13)
        .foregroundStyle(.neutral400)
        .lineLimit(1 ... 3)
        .focused($isCommentFocused)

      Text("\(store.commentText.count)/200")
        .pretendardFont(family: .SemiBold, size: 10)
        .foregroundStyle(.neutral400)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(.beige50)
  }

  @ViewBuilder
  func sendButton() -> some View {
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
}

// MARK: - Format

private extension CommentView {
  func percentText(_ percentage: Double) -> String {
    "\(String(format: "%.1f", percentage * 100))%"
  }

  func formattedCount(_ count: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
  }
}

#Preview {
  CommentView(
    store: Store(initialState: CommentFeature.State()) {
      CommentFeature()
    }
  )
}
