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
      ZStack(alignment: .top) {
        Color.white.ignoresSafeArea()
        artwork(
          width: geometry.size.width,
          height: geometry.size.height * 0.66 + geometry.safeAreaInsets.top
        )
        .offset(y: -geometry.safeAreaInsets.top)

        VStack(spacing: 0) {
          navigationBar
          Spacer(minLength: 0)
          voteContent()
        }
      }
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
      LinearGradient(
        colors: [.black.opacity(0.35), .black.opacity(0.28), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .overlay {
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0.52),
          .init(color: .white, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func voteContent() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("#\(store.room.battle.categoryDisplayTitle)")
        .pickeBadge(.filled, size: .tag)
        .padding(.bottom, 20)

      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 12)

      Text(store.room.battle.summary)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 26)

      participationContent()
        .padding(.bottom, 22)

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
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
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
        title: store.room.battle.optionATitle,
        subtitle: store.room.battle.optionADescription
          ?? store.room.battle.philosopherA
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
        title: store.room.battle.optionBTitle,
        subtitle: store.room.battle.optionBDescription
          ?? store.room.battle.philosopherB
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
      store.room.deadline == .distantFuture
        ? "마감일 없음"
        : store.room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지",
      systemImage: "clock"
    )
    .pretendardFont(.regular13)
    .foregroundStyle(.gray300)
    .frame(maxWidth: .infinity)
  }
}
