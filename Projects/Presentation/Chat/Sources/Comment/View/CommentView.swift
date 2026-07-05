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
import Utill

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
    HStack {
      Button { send(.backButtonTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .regular))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)

      Spacer()

      Text(store.title)
        .pretendardFont(.headingMedium)
        .foregroundStyle(.neutral500)
        .lineLimit(1)

      Spacer()

      Button { send(.forwardTapped) } label: {
        Image(systemName: "chevron.right")
          .font(.system(size: 18, weight: .regular))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
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
    // Figma 7423-7968: 칩 행 py2, gap4, stats 행 py4.
    VStack(spacing: 4) {
      // 사후투표 후 칩을 항상 노출 — 문구는 isMindChanged 에 따라 분기.
      changeBadge()
        .padding(.vertical, 2)

      HStack(alignment: .center, spacing: 12) {
        HStack(spacing: 4) {
          avatarCircle(
            imageUrl: store.voteSummary.optionA.imageUrl,
            name: store.voteSummary.optionA.representative
          )
          Text(percentText(store.voteSummary.optionA.percentage))
            .pretendardFont(.labelSmall)
            .foregroundStyle(.neutral500)
            .fixedSize()
        }
        voteProgress()
        HStack(spacing: 4) {
          Text(percentText(store.voteSummary.optionB.percentage))
            .pretendardFont(.labelSmall)
            .foregroundStyle(.neutral500)
            .fixedSize()
          avatarCircle(
            imageUrl: store.voteSummary.optionB.imageUrl,
            name: store.voteSummary.optionB.representative
          )
        }
      }
      .padding(.vertical, 4)
    }
    .padding(.horizontal, 16)
    .background(.beige50)
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
    .frame(maxWidth: .infinity, alignment: .center)
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
    CommentAvatarView(
      imageURL: imageUrl,
      fallback: name,
      size: 40
    )
  }
}

// MARK: - Filters

private extension CommentView {
  @ViewBuilder
  func filterSection() -> some View {
    // Figma 7423-7968: 필터탭은 탭별 py8 자체 패딩, 그 아래 List 컨테이너 top16 → sort 행(py4).
    VStack(spacing: 16) {
      filterTabs()
      sortRow()
    }
  }

  @ViewBuilder
  func filterTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(CommentFilter.allCases, id: \.self) { filter in
        filterButton(filter)
      }
    }
    .frame(maxWidth: .infinity)
    // 전체 탭을 가로지르는 연속 베이스 라인 (셀별로 끊겨 보이던 문제 해결).
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.neutral200)
        .frame(height: 1)
    }
  }

  @ViewBuilder
  func sortRow() -> some View {
    HStack(spacing: 8) {
      sortButton(.popular)
      sortButton(.latest)
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4) // Figma: sort 행 py4
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
        .pretendardFont(.labelMedium)
        .foregroundStyle(isSelected ? .primary500 : .neutral300)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(isSelected ? .primary500 : .clear)
            .frame(height: 2.5)
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
        .pretendardFont(.medium13)
        .foregroundStyle(isSelected ? .beige50 : .primary500)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          isSelected ? .primary500 : .primary50,
          in: RoundedRectangle(cornerRadius: .radiusDefault)
        )
        .overlay {
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(.primary500, lineWidth: isSelected ? 0 : 1)
        }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Comment List

private extension CommentView {
  @ViewBuilder
  func commentList() -> some View {
    Group {
      if store.isLoadingComments, store.comments.isEmpty {
        CommentSkeletonView()
      } else if store.comments.isEmpty {
        emptyState()
      } else {
        VStack(spacing: 12) {
          ForEach(store.comments) { comment in
            commentCard(comment)
              .overlay(alignment: .topTrailing) {
                if store.menuTargetCommentID == comment.id {
                  inlineMenu(for: comment)
                    .padding(.trailing, 12)
                    .offset(y: 46)
                    .zIndex(1)
                }
              }
              .zIndex(store.menuTargetCommentID == comment.id ? 1 : 0)
          }
        }
        .animation(.easeInOut(duration: 0.18), value: store.menuTargetCommentID)
      }
    }
    .padding(.top, 16) // Figma: List 컨테이너 top16
    .padding(.horizontal, 16)
    .padding(.bottom, 24) // Figma: 댓글모음 pb24
  }

  @ViewBuilder
  func emptyState() -> some View {
    VStack(spacing: 8) {
      Image(systemName: "bubble.left.and.bubble.right")
        .font(.system(size: 32, weight: .light))
        .foregroundStyle(.neutral300)
      Text("아직 등록된 의견이 없어요")
        .pretendardFont(.labelMedium)
        .foregroundStyle(.neutral400)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
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
    .roundedBackground(.beige50)
    .overlay {
      RoundedRectangle(cornerRadius: .radiusDefault)
        .stroke(.beige600, lineWidth: 1)
    }
  }

  @ViewBuilder
  func commentBody(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      Text(comment.content)
        .pretendardFont(.regular13)
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
        Text(comment.isMine ? "나" : comment.author)
          .pretendardFont(.labelMedium)
          .foregroundStyle(.neutral500)
          .lineLimit(1)

        if comment.isMine {
          myBadge()
        }

        Text(comment.timeAgo)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.neutral300)
      }

      optionBadge(comment)
    }
  }

  @ViewBuilder
  func myBadge() -> some View {
    Text("나")
      .pretendardFont(.labelXSmall)
      .foregroundStyle(.beige50)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .roundedBackground(.primary500)
  }

  @ViewBuilder
  func reportButton(commentId: UUID) -> some View {
    Button { send(.commentMenu(id: commentId, action: .more)) } label: {
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
      .pretendardFont(.labelSmall)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .roundedBackground(.beige600)
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
    Button { send(.commentRow(id: commentId, action: .openReply)) } label: {
      Text("더보기")
        .pretendardFont(.labelSmall)
        .foregroundStyle(.neutral300)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func replyCountButton(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .openReply)) } label: {
      actionLabel(systemName: "message", text: "\(comment.replyCount)")
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func likeButton(_ comment: CommentItem) -> some View {
    Button { send(.commentRow(id: comment.id, action: .like)) } label: {
      actionLabel(
        systemName: comment.isLiked ? "heart.fill" : "heart",
        text: comment.likeCount.decimalFormatted
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func actionLabel(
    systemName: String,
    text: String
  ) -> some View {
    HStack(spacing: 4) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 16, height: 16)
      Text(text)
        .pretendardFont(.labelSmall)
    }
  }

  @ViewBuilder
  func avatar(
    urlString: String?,
    fallback: String
  ) -> some View {
    CommentAvatarView(
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
    // Figma 7423-8013: 컨테이너 h128 / pt12 pb24 px16 / gap8, 내부 요소는 세로 중앙(items-center).
    HStack(spacing: 8) {
      inputTextBox()
      sendButton()
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
    // Figma 7423-8014: 입력박스는 flex-1 h-full 로 컨테이너 높이를 꽉 채운다 (px12 py8).
    // 입력 텍스트는 상단, 글자수 카운터는 하단 우측에 배치.
    VStack(alignment: .leading, spacing: 6) {
      TextField("댓글을 입력해주세요", text: $store.commentText, axis: .vertical)
        .pretendardFont(.regular13)
        .foregroundStyle(.neutral400)
        .focused($isCommentFocused)
        .frame(maxWidth: .infinity, alignment: .topLeading)

      Spacer(minLength: 0)

      Text("\(store.commentText.count)/200")
        .pretendardFont(.labelXSmall)
        .foregroundStyle(.neutral400)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(.beige50)
  }

  @ViewBuilder
  func sendButton() -> some View {
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
