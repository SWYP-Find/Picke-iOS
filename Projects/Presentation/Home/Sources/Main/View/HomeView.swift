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
    VStack(spacing: 0) {
      HomeHeaderView { /* TODO: 알림 화면 */ } // sticky — 스크롤 영향 없음

      ScrollView(showsIndicators: false) {
        if shouldShowSkeleton {
          HomeSkeletonContent()
        } else {
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
          .padding(.bottom, 24)
        }
      }
    }
    .background(Color.beige50.ignoresSafeArea())
    .onAppear { send(.onAppear) }
    .navigationBarHidden(true)
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }
}

// MARK: - Sections

extension HomeView {
  private var shouldShowSkeleton: Bool {
    store.isLoading &&
      store.heroes.isEmpty &&
      store.hotBattles.isEmpty &&
      store.bestBattles.isEmpty &&
      store.quizzes.isEmpty &&
      store.votes.isEmpty &&
      store.newBattles.isEmpty
  }

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
        if let quiz = store.currentQuiz {
          QuizCardView(question: quiz)
        }
        if let vote = store.currentVote {
          VoteCardView(question: vote)
        }
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

// MARK: - Skeleton

private struct HomeSkeletonContent: View {
  var body: some View {
    VStack(spacing: 32) {
      HomeHeroSkeletonView()
      HomeHotBattlesSkeletonView()
      HomeBestBattlesSkeletonView()
      HomeTodayPickeSkeletonView()
      HomeNewBattlesSkeletonView()
    }
    .padding(.bottom, 24)
    .allowsHitTesting(false)
  }
}

private struct HomeHeroSkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        SkeletonBlock(width: 82, height: 18, cornerRadius: 2, color: .primary500.opacity(0.45))
        Spacer()
        SkeletonBlock(width: 36, height: 18, cornerRadius: 9, color: .neutral500.opacity(0.5))
      }
      .padding(16)

      ZStack {
        Rectangle()
          .fill(.neutral700.opacity(0.8))
        HStack(spacing: 24) {
          SkeletonBlock(width: 58, height: 14, color: .beige100.opacity(0.24))
          SkeletonBlock(width: 32, height: 32, cornerRadius: 16, color: .beige100.opacity(0.18))
          SkeletonBlock(width: 58, height: 14, color: .beige100.opacity(0.24))
        }
      }
      .frame(height: 167)

      VStack(alignment: .leading, spacing: 8) {
        SkeletonBlock(width: 210, height: 18, color: .beige100.opacity(0.22))
        SkeletonBlock(width: 260, height: 12, color: .neutral200.opacity(0.2))
        HStack {
          SkeletonBlock(width: 92, height: 12, color: .neutral200.opacity(0.18))
          Spacer()
          SkeletonBlock(width: 48, height: 12, color: .neutral200.opacity(0.18))
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 341)
    .background(.neutral800)
  }
}

private struct HomeHotBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SkeletonSectionHeader(width: 132)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(0 ..< 2, id: \.self) { _ in
            VStack(alignment: .leading, spacing: 12) {
              SkeletonBlock(width: 196, height: 124)
              VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 42, height: 20, color: .primary50)
                SkeletonBlock(width: 150, height: 16)
                SkeletonBlock(width: 104, height: 12)
              }
            }
            .padding(12)
            .frame(width: 220, alignment: .leading)
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
            .overlay(
              RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
            )
          }
        }
        .padding(.horizontal, 16)
      }
    }
  }
}

private struct HomeBestBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SkeletonSectionHeader(width: 88)
      VStack(spacing: 0) {
        ForEach(0 ..< 3, id: \.self) { index in
          HStack(alignment: .top, spacing: 16) {
            SkeletonBlock(width: 18, height: 28, color: index == 0 ? .primary500.opacity(0.35) : .neutral100)
            VStack(alignment: .leading, spacing: 10) {
              SkeletonBlock(width: 76, height: 18, color: .primary50)
              SkeletonBlock(width: 214, height: 16)
              HStack(spacing: 8) {
                SkeletonBlock(width: 40, height: 12)
                SkeletonBlock(width: 44, height: 12)
                Spacer()
                SkeletonBlock(width: 96, height: 12)
              }
            }
          }
          .padding(.vertical, 16)

          if index < 2 {
            Divider()
              .background(.beige600)
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct HomeTodayPickeSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      SkeletonSectionHeader(width: 104)
      VStack(spacing: 16) {
        todayQuizCard()
        todayVoteCard()
      }
      .padding(.horizontal, 16)
    }
  }

  private func todayQuizCard() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        SkeletonBlock(width: 42, height: 20, color: .primary50)
        Spacer()
        SkeletonBlock(width: 76, height: 12)
      }
      VStack(spacing: 8) {
        SkeletonBlock(width: 220, height: 16)
        SkeletonBlock(width: 260, height: 12)
        SkeletonBlock(width: 180, height: 12)
      }
      .frame(maxWidth: .infinity)

      HStack(spacing: 8) {
        SkeletonBlock(height: 74, color: .beige50)
        SkeletonBlock(height: 74, color: .beige50)
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .background(.beige400, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige700, lineWidth: 1)
    )
  }

  private func todayVoteCard() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        SkeletonBlock(width: 42, height: 20, color: .primary50)
        Spacer()
        SkeletonBlock(width: 76, height: 12)
      }
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          SkeletonBlock(width: 78, height: 16)
          SkeletonBlock(width: 44, height: 24, color: .beige50)
          SkeletonBlock(width: 24, height: 16)
        }
        SkeletonBlock(width: 230, height: 12)
      }
      .frame(maxWidth: .infinity)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
        ForEach(0 ..< 4, id: \.self) { _ in
          SkeletonBlock(height: 44, color: .beige50)
        }
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige700, lineWidth: 1)
    )
  }
}

private struct HomeNewBattlesSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      SkeletonSectionHeader(width: 104)
      VStack(spacing: 12) {
        ForEach(0 ..< 3, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              SkeletonBlock(width: 42, height: 20, color: .primary50)
              Spacer()
              SkeletonBlock(width: 92, height: 12)
            }
            SkeletonBlock(width: 240, height: 16)
            SkeletonBlock(width: 300, height: 12)
            HStack(spacing: 8) {
              SkeletonBattleOption()
              SkeletonBlock(width: 32, height: 32, cornerRadius: 16, color: .secondary100)
              SkeletonBattleOption()
            }
          }
          .padding(12)
          .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
          .overlay(
            RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct SkeletonBattleOption: View {
  var body: some View {
    HStack(spacing: 8) {
      SkeletonBlock(width: 28, height: 28, cornerRadius: 14, color: .beige500)
      VStack(alignment: .leading, spacing: 4) {
        SkeletonBlock(width: 46, height: 12)
        SkeletonBlock(width: 28, height: 10)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1)
    )
  }
}

private struct SkeletonSectionHeader: View {
  let width: CGFloat

  var body: some View {
    HStack {
      SkeletonBlock(width: width, height: 22, color: .neutral100)
      Spacer()
      SkeletonBlock(width: 40, height: 14)
    }
    .padding(.horizontal, 16)
  }
}

private struct SkeletonBlock: View {
  var width: CGFloat?
  var height: CGFloat
  var cornerRadius: CGFloat
  var color: Color

  init(
    width: CGFloat? = nil,
    height: CGFloat,
    cornerRadius: CGFloat = 2,
    color: Color = .beige600.opacity(0.55)
  ) {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
    self.color = color
  }

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(color)
      .frame(width: width, height: height)
      .frame(maxWidth: width == nil ? .infinity : nil)
  }
}

#Preview {
  HomeView(
    store: Store(initialState: HomeFeature.State()) { HomeFeature() }
  )
}
