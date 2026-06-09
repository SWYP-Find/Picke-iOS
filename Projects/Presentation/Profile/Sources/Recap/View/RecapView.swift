//
//  RecapView.swift
//  Profile
//
//  나의 철학자 유형(리캡) UI — picke.pen `나의 철학자 유형`.
//  내 카드 + 성향 분석(레이더/바) + 내 취향 리포트 + 궁합 유형 + 공유하기.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: RecapFeature.self)
public struct RecapView: View {
  @Bindable public var store: StoreOf<RecapFeature>

  public init(store: StoreOf<RecapFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "나의 철학자 유형") {
        Button { send(.shareTapped) } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(.neutral900)
            .frame(width: 24, height: 24)
        }
      }
      .foregroundStyle(.gray500)

      if let recap = store.recap {
        content(recap)
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
      .pretendardFont(family: .SemiBold, size: 13)
      .foregroundStyle(.gray800)
      .frame(maxWidth: .infinity, alignment: .center)
  }

  @ViewBuilder
  func card(@ViewBuilder _ content: () -> some View) -> some View {
    content()
      .frame(maxWidth: .infinity)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
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
        .pretendardFont(family: .Bold, size: 16)
        .foregroundStyle(.gray800)
      Text(label)
        .pretendardFont(family: .Medium, size: 10)
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
        .pretendardFont(family: .Bold, size: 10)
        .foregroundStyle(.secondary500)
      Text(topic.tagText)
        .pretendardFont(family: .Medium, size: 12)
        .foregroundStyle(.gray800)
      Spacer(minLength: 6)
      Text("\(topic.participationCount)회")
        .pretendardFont(family: .Medium, size: 10)
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
      send(.shareTapped)
    } label: {
      HStack(spacing: 6) {
        Text("공유하기")
          .pretendardFont(family: .SemiBold, size: 16)
          .foregroundStyle(.beige50)
        Image(systemName: "square.and.arrow.up")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.beige50)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .background(.primary500, in: RoundedRectangle(cornerRadius: 2))
    }
    .buttonStyle(.plain)
  }
}
