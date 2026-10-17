//
//  ClassReplyDetailView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassReplyDetailFeature.self)
public struct ClassReplyDetailView: View {
  @Bindable public var store: StoreOf<ClassReplyDetailFeature>

  public init(store: StoreOf<ClassReplyDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)
      contentSection()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassReplyDetailView {
  @ViewBuilder
  func contentSection() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        opinionSection()
        repliesSection()
      }
      .padding(16)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  func opinionSection() -> some View {
    if let opinion = store.opinion {
      VStack(alignment: .leading, spacing: 12) {
        sectionHeading("댓글")
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 8) {
            PickeAvatarView(imageURL: nil, fallback: opinion.author, size: 36)
            Text(opinion.author)
              .pretendardFont(.semiBold15)
              .foregroundStyle(.gray800)
              .lineLimit(1)
            Spacer()
          }
          Text(opinion.text)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray700)
            .frame(maxWidth: .infinity, alignment: .leading)
          HStack(spacing: 16) {
            if let count = opinion.recommendationCount {
              Label(count.decimalFormatted, systemImage: "heart")
                .accessibilityLabel("추천 \(count.decimalFormatted)개")
            }
            Label(opinion.replyCount.decimalFormatted, systemImage: "bubble.right")
              .accessibilityLabel("대댓글 \(opinion.replyCount.decimalFormatted)개")
          }
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
      }
    }
  }

  @ViewBuilder
  func repliesSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeading("대댓글")
      switch store.viewState {
      case .unavailable:
        statusMessage("대댓글을 불러올 수 없어요.")
      case .empty:
        statusMessage("아직 대댓글이 없어요.")
      case let .loaded(replies):
        ForEach(replies) { reply in
          replyCard(reply)
        }
      }
    }
  }

  func sectionHeading(_ title: String) -> some View {
    Text(title)
      .pretendardFont(family: .SemiBold, size: 13)
      .foregroundStyle(.gray800)
      .accessibilityAddTraits(.isHeader)
  }

  func statusMessage(_ message: String) -> some View {
    Text(message)
      .pretendardFont(.regular13)
      .foregroundStyle(.gray300)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
  }

  @ViewBuilder
  func replyCard(_ reply: ClassReplyDetailFeature.State.Reply) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        PickeAvatarView(imageURL: nil, fallback: reply.author, size: 32)
        Text(reply.author)
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.gray800)
          .lineLimit(1)
        Spacer()
        Text(reply.date)
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.gray300)
          .fixedSize()
      }
      Text(reply.body)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}
