//
//  ClassAIVoteView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassAIVoteFeature.self)
public struct ClassAIVoteView: View {
  @Bindable public var store: StoreOf<ClassAIVoteFeature>
  private let onAppear: (@MainActor () -> Void)?

  public init(
    store: StoreOf<ClassAIVoteFeature>,
    onAppear: (@MainActor () -> Void)? = nil
  ) {
    self.store = store
    self.onAppear = onAppear
  }

  public var body: some View {
    GeometryReader { geometry in
      page(in: geometry)
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear {
      if let onAppear {
        onAppear()
      } else {
        send(.onAppear)
      }
    }
  }
}

private extension ClassAIVoteView {
  static let optionMinHeight: CGFloat = 57

  @ViewBuilder
  func page(in geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      navigationBar
      scrollContent(width: geometry.size.width)
    }
    .background(alignment: .top) {
      artwork(
        width: geometry.size.width,
        height: geometry.size.width * 512 / 375
      )
      .offset(y: -geometry.safeAreaInsets.top)
    }
    .background { Color.white.ignoresSafeArea() }
  }

  @ViewBuilder
  func scrollContent(width: CGFloat) -> some View {
    GeometryReader { viewport in
      ScrollView {
        VStack(spacing: 0) {
          Spacer(minLength: 205.914 * width / 375)
          voteContent(width: width)
        }
        .frame(minHeight: viewport.size.height)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
    }
  }

  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: store.room.name
    )
    .foregroundStyle(.white)
  }

  @ViewBuilder
  func artwork(
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    Group {
      if store.room.battle.thumbnailURL == nil {
        Image(asset: .classAIVoteArtwork)
          .resizable()
          .scaledToFill()
      } else {
        AsyncImage(url: store.room.battle.thumbnailURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.beige600
        }
      }
    }
    .frame(width: width, height: height)
    .clipped()
    .overlay {
      Color.black.opacity(0.4)
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func voteContent(width: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      metadataRow()
        .padding(.bottom, 20)

      Text(store.room.battle.title)
        .pretendardFont(.bold24)
        .foregroundStyle(.gray800)
        .lineSpacing(titleLinePadding)
        .padding(.vertical, titleLinePadding / 2)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 287 * width / 375, alignment: .leading)
        .padding(.bottom, 12)

      Text(store.room.battle.summary)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray400)
        .lineSpacing(summaryLinePadding)
        .padding(.vertical, summaryLinePadding / 2)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 40)

      participationContent()
        .padding(.bottom, 20)

      if store.viewState == .loaded, let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.regular13)
          .foregroundStyle(.primary500)
          .padding(.bottom, 8)
      }

      Button(store.submitTitle) {
        send(.submitTapped)
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(!store.canSubmit)

      deadlineLabel
        .padding(.top, 8)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background { contentBackground(width: width) }
  }

  @ViewBuilder
  func contentBackground(width: CGFloat) -> some View {
    // Source 13384:59439: content y434, white fade y228.086...440.424.
    // Anchor the fade to content so longer text and short screens stay legible.
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Color.white
          .offset(y: 6.424 * width / 375)
        LinearGradient(
          colors: [.white.opacity(0), .white],
          startPoint: .init(x: 0.5, y: 0),
          endPoint: .init(x: 188.037 / 375, y: 1)
        )
        .frame(height: 212.338 * width / 375)
        .offset(y: -205.914 * width / 375)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .accessibilityHidden(true)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  func metadataRow() -> some View {
    HStack(alignment: .top, spacing: 8) {
      categoryBadge
      Spacer(minLength: 0)
      if let count = store.commentCountTitle {
        commentCountBadge(count)
      }
    }
    .frame(minHeight: 25, alignment: .top)
  }

  var categoryBadge: some View {
    Text(store.categoryTitle)
      .pretendardFont(.semiBold12)
      .foregroundStyle(.badgeFilledText)
      .lineLimit(1)
      .frame(height: 16)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(.badgeFilledBackground, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func commentCountBadge(_ count: String) -> some View {
    HStack(spacing: 2) {
      Image(asset: .commentMessage)
        .resizable()
        .frame(width: 16, height: 16)
      Text(count)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
        .fixedSize()
        .frame(height: 17)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .background(.white, in: RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .strokeBorder(Color(hex: "DFDFDF"), lineWidth: 1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(store.commentAccessibilityLabel)
  }

  @ViewBuilder
  func participationContent() -> some View {
    switch store.viewState {
    case .loading:
      HStack(spacing: 8) {
        SkeletonView(.rect)
        SkeletonView(.rect)
      }
      .frame(height: Self.optionMinHeight)
      .accessibilityLabel("투표 상태를 불러오는 중")
    case .error:
      VStack(spacing: 10) {
        Text("투표 상태를 불러오지 못했어요")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray500)
        Button("다시 시도") { send(.retryTapped) }
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: Self.optionMinHeight)
    case .loaded:
      voteOptions()
    }
  }

  @ViewBuilder
  func voteOptions() -> some View {
    HStack(spacing: 0) {
      optionCard(
        id: 1,
        title: store.optionATitle,
        subtitle: store.optionASubtitle
      )
      Text("vs")
        .pretendardFont(.semiBold11)
        .foregroundStyle(.gray800)
        .frame(width: 28, height: 28)
        .background(.secondary200, in: Circle())
        .padding(.horizontal, -10)
        .zIndex(1)
      optionCard(
        id: 2,
        title: store.optionBTitle,
        subtitle: store.optionBSubtitle
      )
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  func optionCard(
    id: Int,
    title: String,
    subtitle: String
  ) -> some View {
    let isSelected = store.selectedOptionID == id
    return Button { send(.optionTapped(id)) } label: {
      VStack(spacing: 2) {
        Text(title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray800)
          .lineLimit(2)
          .lineSpacing(optionTitleLinePadding)
          .padding(.vertical, optionTitleLinePadding / 2)
          .fixedSize(horizontal: false, vertical: true)
        Text(subtitle)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
          .lineLimit(1)
          .padding(.vertical, optionDescriptionLinePadding / 2)
      }
      .multilineTextAlignment(.center)
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .frame(
        maxWidth: .infinity,
        minHeight: Self.optionMinHeight,
        maxHeight: .infinity
      )
      .background(
        isSelected ? Color.beige400 : .beige300,
        in: RoundedRectangle(cornerRadius: 2)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .strokeBorder(isSelected ? Color.secondary500 : .beige600, lineWidth: 1)
      }
      .opacity(isSelected ? 1 : 0.88)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  var optionTitleLinePadding: CGFloat {
    max(0, 20 - UIFont.pretendardFontFamily(family: .SemiBold, size: 14).lineHeight)
  }

  var optionDescriptionLinePadding: CGFloat {
    max(0, 17 - UIFont.pretendardFontFamily(family: .Medium, size: 12).lineHeight)
  }

  var deadlineLabel: some View {
    Label(
      store.deadlineTitle,
      systemImage: "clock"
    )
    .pretendardFont(.regular13)
    .foregroundStyle(.gray300)
    .padding(.vertical, deadlineLinePadding / 2)
    .frame(maxWidth: .infinity)
  }

  var titleLinePadding: CGFloat {
    max(0, 31.2 - UIFont.pretendardFontFamily(family: .Bold, size: 24).lineHeight)
  }

  var summaryLinePadding: CGFloat {
    max(0, 19.6 - UIFont.pretendardFontFamily(family: .Regular, size: 14).lineHeight)
  }

  var deadlineLinePadding: CGFloat {
    max(0, 18 - UIFont.pretendardFontFamily(family: .Regular, size: 13).lineHeight)
  }
}
