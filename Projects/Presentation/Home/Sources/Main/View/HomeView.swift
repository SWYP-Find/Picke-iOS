//
//  HomeView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem
import Entity

import ComposableArchitecture

@ViewAction(for: HomeFeature.self)
public struct HomeView: View {
  @Bindable public var store: StoreOf<HomeFeature>

  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  public var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 0) {
        HomeHeaderView { /* TODO: 알림 화면 */ }
        VStack(spacing: 32) {
          HeroCarouselView(
            heroes: store.heroes,
            currentIndex: $store.heroIndex
          )
          hotBattlesSection()
          bestBattlesSection()
          todayPickeSection()
          newBattlesSection()
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
      }
    }
    .background(Color.beige50.ignoresSafeArea())
    .onAppear { send(.onAppear) }
    .navigationBarHidden(true)
  }
}

// MARK: - Sections

extension HomeView {
  private func hotBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HomeSectionHeader(title: "지금 뜨는 배틀") {
        send(.seeMoreTapped(.hotBattles))
      }
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(store.hotBattles) { HotBattleCardView(battle: $0) }
        }
        .padding(.horizontal, 16)
      }
    }
  }

  private func bestBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HomeSectionHeader(title: "Best 배틀") {
        send(.seeMoreTapped(.bestBattles))
      }
      VStack(spacing: 12) {
        ForEach(store.bestBattles) { BestBattleCardView(battle: $0) }
      }
      .padding(.horizontal, 16)
    }
  }

  private func todayPickeSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HomeSectionHeader(title: "오늘의 Pické") {
        send(.seeMoreTapped(.todayPicke))
      }
      VStack(spacing: 16) {
        QuizCardView(question: store.quiz)
        VoteCardView(question: store.vote)
      }
      .padding(.horizontal, 16)
    }
  }

  private func newBattlesSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HomeSectionHeader(title: "새로운 배틀") {
        send(.seeMoreTapped(.newBattles))
      }
      VStack(spacing: 12) {
        ForEach(store.newBattles) { NewBattleCardView(battle: $0) }
      }
      .padding(.horizontal, 16)
    }
  }
}

#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State()) { HomeFeature() }
  )
}
