//
//  RecapView.swift
//  Profile
//

import SwiftUI

import ComposableArchitecture
import PickeDesignKit
import Entity
import Kingfisher

@ViewAction(for: RecapFeature.self)
public struct RecapView: View {
  @Bindable public var store: StoreOf<RecapFeature>

  public init(store: StoreOf<RecapFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "나의 철학자 유형") {
        Button { shareWithSnapshot() } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(.neutral900)
            .frame(width: 24, height: 24)
        }
      }
      .foregroundStyle(.gray500)

      if let recap = store.recap {
        if store.isLocked {
          RecapLockedView()
        } else {
          content(recap)
        }
      } else {
        RecapSkeletonView()
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
    }
    .onAppear { send(.onAppear) }
  }
}

private extension RecapView {
  @ViewBuilder
  func content(_ recap: PhilosopherRecap) -> some View {
    ScrollView {
      VStack(spacing: 24) {
        RecapPhilosopherCard(card: recap.myCard)
        tendencySection(recap.scores)
        reportSection(recap.preferenceReport)
        matchSection(recap)
        shareButton()
      }
      .padding(.top, 20)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }

  // MARK: 공통 섹션 (헤딩 + 카드)

  @ViewBuilder
  func sectionHeading(_ title: String) -> some View {
    Text(title)
      .pretendardFont(.semiBold13)
      .foregroundStyle(.gray800)
      .frame(maxWidth: .infinity, alignment: .center)
  }

  @ViewBuilder
  func card(@ViewBuilder _ content: () -> some View) -> some View {
    content()
      .frame(maxWidth: .infinity)
      .roundedBackground(.beige50)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(.beige600, lineWidth: 1)
      )
  }

  // MARK: 성향 분석

  @ViewBuilder
  func tendencySection(_ scores: RecapScores) -> some View {
    VStack(spacing: 12) {
      sectionHeading("성향 분석")
      card {
        VStack(spacing: 8) {
          RecapRadarChart(axes: scores.axes)
            .frame(height: 172)

          LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
          ) {
            // picke.pen 그리드 순서: 원칙·이성 / 개인·변화 / 내면·이상
            ForEach(scores.gridAxes) { axis in
              RecapScoreBar(axis: axis)
            }
          }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
      }
    }
  }

  // MARK: 내 취향 리포트

  @ViewBuilder
  func reportSection(_ report: PreferenceReport) -> some View {
    VStack(spacing: 12) {
      sectionHeading("내 취향 리포트")
      card {
        VStack(spacing: 20) {
          HStack(spacing: 0) {
            statCell(value: "\(report.totalParticipation)", label: "총 참여", divider: true)
            statCell(value: "\(report.opinionChanges)", label: "의견 전환", divider: true)
            statCell(value: "\(report.battleWinRate)%", label: "배틀 승률", divider: false)
          }
          .padding(.horizontal, 16)

          VStack(spacing: 0) {
            ForEach(report.favoriteTopics) { topic in
              topicRow(topic)
            }
          }
        }
        .padding(.top, 16)
      }
    }
  }

  @ViewBuilder
  func statCell(value: String, label: String, divider: Bool) -> some View {
    VStack(spacing: 0) {
      Text(value)
        .pretendardFont(.labelLarge)
        .foregroundStyle(.gray800)
      Text(label)
        .pretendardFont(.medium10)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
    .overlay(alignment: .trailing) {
      if divider {
        Rectangle().fill(.beige600).frame(width: 1, height: 28)
      }
    }
  }

  @ViewBuilder
  func topicRow(_ topic: FavoriteTopic) -> some View {
    HStack(spacing: 6) {
      Text(String(format: "%02d", topic.rank))
        .pretendardFont(.bold10)
        .foregroundStyle(.secondary500)
      Text(topic.tagText)
        .pretendardFont(.labelSmall)
        .foregroundStyle(.gray800)
      Spacer(minLength: 6)
      Text("\(topic.participationCount)회")
        .pretendardFont(.medium10)
        .foregroundStyle(.gray300)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .overlay(alignment: .top) {
      Rectangle().fill(.beige600).frame(height: 1)
    }
  }

  // MARK: 궁합 유형

  @ViewBuilder
  func matchSection(_ recap: PhilosopherRecap) -> some View {
    VStack(spacing: 12) {
      sectionHeading("궁합 유형")
      HStack(spacing: 8) {
        RecapMatchCard(card: recap.bestMatchCard, isBest: true)
        RecapMatchCard(card: recap.worstMatchCard, isBest: false)
      }
    }
  }

  // MARK: 공유하기

  @ViewBuilder
  func shareButton() -> some View {
    Button {
      shareWithSnapshot()
    } label: {
      HStack(spacing: 6) {
        Text("공유하기")
          .pretendardFont(.headingMedium)
          .foregroundStyle(.beige50)
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.beige50)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .roundedBackground(.primary500)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - 공유 스냅샷 (인스타 스토리/게시물용 카드 이미지)

private extension RecapView {
  /// 공유 트리거 — 아바타(철학자) 이미지를 먼저 비동기 로드한 뒤 카드 스냅샷을 렌더한다.
  /// KFImage 는 ImageRenderer(동기 렌더) 에서 로드 전이라 빈 이미지로 캡처되므로(=스토리에 이미지 누락),
  /// Kingfisher 로 미리 받아 `avatarOverride` 로 주입해 동기 렌더한다.
  func shareWithSnapshot() {
    Task { @MainActor in
      let avatar = await loadAvatarImage()
      send(.shareTapped(snapshot: captureCardSnapshot(avatar: avatar)))
    }
  }

  /// 카드 아바타 원격 이미지를 Kingfisher 로 선로드 (없거나 실패 시 nil → SF Symbol 폴백).
  @MainActor
  func loadAvatarImage() async -> UIImage? {
    guard let recap = store.recap,
          !recap.myCard.imageURL.isEmpty,
          let url = URL(string: recap.myCard.imageURL)
    else { return nil }
    return await withCheckedContinuation { continuation in
      KingfisherManager.shared.retrieveImage(with: url) { result in
        continuation.resume(returning: try? result.get().image)
      }
    }
  }

  /// 철학자 유형 카드를 이미지로 렌더해 PNG 데이터로 반환. (없으면 nil → 텍스트/URL 공유로 폴백)
  @MainActor
  func captureCardSnapshot(avatar: UIImage?) -> Data? {
    guard let recap = store.recap else { return nil }
    let renderer = ImageRenderer(content: shareSnapshotCard(recap.myCard, avatar: avatar))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage?.pngData()
  }

  /// 공유용 카드 레이아웃 — 카드 + 배경 패딩 (외부 의존 없이 단독 렌더 가능).
  @ViewBuilder
  func shareSnapshotCard(_ card: RecapCard, avatar: UIImage?) -> some View {
    RecapPhilosopherCard(card: card, avatarOverride: avatar)
      .padding(20)
      .frame(width: 340)
      .background(.beige200)
  }
}
