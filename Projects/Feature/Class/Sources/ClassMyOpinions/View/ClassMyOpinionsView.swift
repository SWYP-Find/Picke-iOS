//
//  ClassMyOpinionsView.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassMyOpinionsFeature.self)
public struct ClassMyOpinionsView: View {
  @Bindable public var store: StoreOf<ClassMyOpinionsFeature>

  public init(store: StoreOf<ClassMyOpinionsFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar()
      contentSection()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension ClassMyOpinionsView {
  @ViewBuilder
  func navigationBar() -> some View {
    ZStack {
      Text("내가 남긴 의견")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray500)

      HStack {
        backButton
        Spacer()
      }
      .padding(.horizontal, 6)
    }
    .frame(height: 48)
  }

  var backButton: some View {
    Button { send(.backTapped) } label: {
      Path { path in
        path.move(to: CGPoint(x: 17, y: 2))
        path.addLine(to: CGPoint(x: 7, y: 12))
        path.addLine(to: CGPoint(x: 17, y: 22))
      }
      .stroke(.gray900, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
      .frame(width: 24, height: 24)
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("뒤로")
    .accessibilityIdentifier("class-my-opinions-back")
  }

  @ViewBuilder
  func contentSection() -> some View {
    ScrollView {
      if store.isLoading {
        ProgressView("내 의견을 불러오는 중")
          .frame(maxWidth: .infinity)
          .padding(24)
      } else if let errorMessage = store.errorMessage {
        PickeRetryErrorView(message: errorMessage) { send(.retryTapped) }
      } else if store.isEmpty {
        emptyState
      } else {
        VStack(alignment: .leading, spacing: 20) {
          if !store.comments.isEmpty {
            opinionSection("남긴 댓글", rows: store.comments, headingGap: 16)
          }
          if !store.replies.isEmpty {
            opinionSection("남긴 대댓글", rows: store.replies, headingGap: 12)
          }
          if !store.unspecified.isEmpty {
            opinionSection("남긴 의견", rows: store.unspecified, headingGap: 12)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
      }
    }
    .scrollIndicators(.hidden)
  }

  var emptyState: some View {
    Text("아직 남긴 의견이 없어요.")
      .pretendardFont(.regular13)
      .foregroundStyle(.gray300)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
  }

  @ViewBuilder
  func opinionSection(
    _ title: String,
    rows: [ClassMyOpinionRow],
    headingGap: CGFloat
  ) -> some View {
    VStack(alignment: .leading, spacing: headingGap) {
      Text(title)
        .pretendardFont(family: .SemiBold, size: 13)
        .foregroundStyle(.gray800)
        .frame(minHeight: 18)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 12) {
        ForEach(rows) { row in
          opinionCard(row)
        }
      }
    }
  }

  @ViewBuilder
  func opinionCard(_ row: ClassMyOpinionRow) -> some View {
    Group {
      switch row.opinion.kind {
      case .comment:
        commentCard(row)
      case .reply:
        replyCard(row)
      case .unspecified:
        unspecifiedCard(row.opinion)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier(row.accessibilityID)
  }

  @ViewBuilder
  func commentCard(_ row: ClassMyOpinionRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      if let stance = row.opinion.stance {
        Text(stance)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.badgeFilledText)
          .lineLimit(1)
          .frame(minHeight: 20)
          .padding(.horizontal, 4)
          .background(.badgeFilledBackground, in: RoundedRectangle(cornerRadius: 2))
      }
      Text(row.opinion.body)
        .pretendardFont(family: .Regular, size: 13)
        .foregroundStyle(.gray300)
        .lineSpacing(bodyLinePadding)
        .padding(.vertical, bodyLinePadding / 2)
        .lineLimit(3)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
      if row.likesText != nil || row.repliesText != nil {
        reactions(row)
          .padding(.top, 4)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cardSurface, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func reactions(_ row: ClassMyOpinionRow) -> some View {
    HStack(spacing: 8) {
      Spacer()
      if let likes = row.likesText, let label = row.likesAccessibilityLabel {
        HStack(spacing: 2) {
          Image(asset: .heartPlus)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(likes)
        }
        .accessibilityLabel(label)
      }
      if let replies = row.repliesText, let label = row.repliesAccessibilityLabel {
        HStack(spacing: 2) {
          Image(asset: .commentMessage)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
          Text(replies)
        }
        .accessibilityLabel(label)
      }
    }
    .pretendardFont(family: .Regular, size: 12)
    .foregroundStyle(.gray300)
    .frame(minHeight: 17)
  }

  @ViewBuilder
  func replyCard(_ row: ClassMyOpinionRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      if let parent = row.opinion.parent {
        parentPreview(parent, stanceLabel: row.parentStanceLabel)
      }
      VStack(alignment: .leading, spacing: 4) {
        if let label = row.replyAuthorLabel {
          HStack(spacing: 4) {
            replyArrow
            Text(label)
          }
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.primary500)
          .frame(minHeight: 17)
        }
        Text(row.opinion.body)
          .pretendardFont(family: .Regular, size: 13)
          .foregroundStyle(.gray400)
          .lineSpacing(bodyLinePadding)
          .padding(.vertical, bodyLinePadding / 2)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cardSurface, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func parentPreview(
    _ parent: ClassReportReplyContext,
    stanceLabel: String?
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if parent.authorName != nil || parent.stance != nil {
        HStack(spacing: 4) {
          if let author = parent.authorName {
            Text(author).foregroundStyle(.gray800)
          }
          if let stanceLabel {
            Text(stanceLabel).foregroundStyle(.gray300)
          }
        }
        .pretendardFont(family: .SemiBold, size: 12)
        .frame(minHeight: 17)
      }
      Text(parent.body)
        .pretendardFont(family: .Regular, size: 12)
        .foregroundStyle(.gray300)
        .lineLimit(1)
        .frame(minHeight: 17)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func unspecifiedCard(_ opinion: ClassReportOpinion) -> some View {
    Text(opinion.body)
      .pretendardFont(family: .Regular, size: 13)
      .foregroundStyle(.gray400)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(cardSurface, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.beige600, lineWidth: 1))
  }

  var replyArrow: some View {
    Path { path in
      path.move(to: CGPoint(x: 1, y: 1))
      path.addLine(to: CGPoint(x: 1, y: 5))
      path.addQuadCurve(to: CGPoint(x: 4, y: 8), control: CGPoint(x: 1, y: 8))
      path.addLine(to: CGPoint(x: 11, y: 8))
      path.move(to: CGPoint(x: 7, y: 4))
      path.addLine(to: CGPoint(x: 11, y: 8))
      path.addLine(to: CGPoint(x: 7, y: 12))
    }
    .stroke(.primary500, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
    .frame(width: 12, height: 12)
    .accessibilityHidden(true)
  }

  var bodyLinePadding: CGFloat {
    max(0, 18 - UIFont.pretendardFontFamily(family: .Regular, size: 13).lineHeight)
  }

  var cardSurface: Color { Color(hex: "FEFEFE") }
}
