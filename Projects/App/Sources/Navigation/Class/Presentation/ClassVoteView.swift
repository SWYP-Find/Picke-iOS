//
//  ClassVoteView.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import FeatureAssembly
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: PreVoteFeature.self)
struct ClassVoteView: View {
  @Bindable var store: StoreOf<PreVoteFeature>
  private let room: ClassRoom

  init(
    store: StoreOf<PreVoteFeature>,
    room: ClassRoom
  ) {
    self.store = store
    self.room = room
  }

  var body: some View {
    Group {
      if store.detailLoadFailed, store.battle == nil {
        loadErrorContent()
      } else if store.viewState == .loading || store.battle == nil || store.isCheckingParticipation {
        loadingContent()
      } else if let battle = store.battle {
        loadedContent(battle)
      }
    }
    .background(screenBackground.ignoresSafeArea())
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    .onChange(of: store.shareSnapshotRequest) { _, request in
      guard request != nil else { return }
      send(.shareSnapshotRendered(nil))
    }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
        .toolbar(.hidden, for: .navigationBar)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

private extension ClassVoteView {
  var isPostVote: Bool {
    store.voteMode == .post
  }

  var screenBackground: Color {
    isPostVote ? .black : .beige50
  }

  @ViewBuilder
  func loadErrorContent() -> some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backButtonTapped) }, centerTitle: isPostVote ? nil : room.name)
        .foregroundStyle(.neutral800)
      PickeRetryErrorView(message: "배틀을 불러오지 못했어요") { send(.retryTapped) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.beige50.ignoresSafeArea())
  }

  @ViewBuilder
  func loadingContent() -> some View {
    VStack(alignment: .leading, spacing: 18) {
      PickeNavigationBar(onBack: { send(.backButtonTapped) }, centerTitle: isPostVote ? nil : room.name)
        .foregroundStyle(isPostVote ? .beige50 : .neutral800)
      SkeletonView(.round(cornerRadius: 6)).frame(height: 300)
      SkeletonView(.round(cornerRadius: 6)).frame(width: 190, height: 28)
      SkeletonView(.round(cornerRadius: 6)).frame(height: 52)
      Spacer()
      SkeletonView(.round(cornerRadius: 6)).frame(height: 52)
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func loadedContent(_ battle: PreVoteBattle) -> some View {
    GeometryReader { geometry in
      let artworkHeight = max(360, geometry.size.height * 0.62 + geometry.safeAreaInsets.top)

      ZStack(alignment: .top) {
        artwork(battle, width: geometry.size.width, height: artworkHeight)
          .offset(y: -geometry.safeAreaInsets.top)

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: max(0, artworkHeight - 110))
            voteContent(battle)
          }
          .frame(minHeight: geometry.size.height - 98, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          actionFooter()
        }

        navigationBar()
      }
    }
  }

  @ViewBuilder
  func navigationBar() -> some View {
    PickeNavigationBar(
      onBack: { send(.backButtonTapped) },
      centerTitle: isPostVote ? nil : room.name
    ) {
      if isPostVote {
        Button { send(.shareTapped) } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 24, weight: .regular))
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("공유하기")
      }
    }
    .foregroundStyle(.beige50)
  }

  @ViewBuilder
  func artwork(
    _ battle: PreVoteBattle,
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    Group {
      if let imageURL = battle.backgroundImageURL, let url = URL(string: imageURL) {
        PickeRemoteImage(url: url)
      } else {
        Color.neutral200
      }
    }
    .frame(width: width, height: height)
    .clipped()
    .overlay(.black.opacity(0.35))
    .overlay {
      LinearGradient(
        stops: [
          .init(color: .clear, location: 0.42),
          .init(color: screenBackground.opacity(0.72), location: 0.82),
          .init(color: screenBackground, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  func voteContent(_ battle: PreVoteBattle) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 9) {
        ForEach(battle.tags, id: \.self) { tag in
          Text(tag).pickeBadge(.filled, size: .tag)
        }
      }
      .padding(.bottom, 20)

      Text([battle.titleLine1, battle.titleLine2].filter { !$0.isEmpty }.joined(separator: "\n"))
        .pretendardFont(.bold24)
        .foregroundStyle(isPostVote ? .beige50 : .neutral500)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 12)

      Text(battle.summary)
        .pretendardFont(.regular13)
        .foregroundStyle(.neutral400)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 26)

      optionSection(battle)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 22)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func optionSection(_ battle: PreVoteBattle) -> some View {
    ZStack {
      HStack(spacing: 8) {
        optionCard(battle.leftOption)
        optionCard(battle.rightOption)
      }

      Text("VS")
        .pretendardFont(.bold11)
        .foregroundStyle(.neutral800)
        .frame(width: 28, height: 28)
        .background(.secondary200, in: Circle())
        .overlay(Circle().stroke(.beige50, lineWidth: 1.5))
    }
  }

  @ViewBuilder
  func optionCard(_ option: PreVoteOption) -> some View {
    let isSelected = store.selectedOptionId == option.optionId
    Button { send(.optionTapped(optionId: option.optionId)) } label: {
      VStack(spacing: 8) {
        PickeRemoteImage(url: option.imageURL) {
          SkeletonView(.round()).frame(width: 28, height: 20)
        }
        .content(.fit)
        .frame(width: 40, height: 40)
        .background(.beige600, in: Circle())

        Text(option.stance)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral600)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .multilineTextAlignment(.center)

        Text(option.representative)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.neutral300)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 106)
      .pickeCard(
        .beige300,
        border: isSelected ? (isPostVote ? .secondary500 : .beige700) : .beige500
      )
    }
    .buttonStyle(.plain)
    .disabled(store.isSubmitting)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder
  func actionFooter() -> some View {
    VStack(spacing: 8) {
      Button(store.primaryButtonTitle) { send(.primaryButtonTapped) }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(!store.isPrimaryButtonEnabled)

      if !isPostVote, room.deadline != .distantFuture {
        Label(room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지", systemImage: "clock")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .background(screenBackground)
  }
}
