//
//  CurationView.swift
//  Chat
//
//  .pen `큐레이팅 화면` — 흥미 기반 배틀 추천 목록.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity

@ViewAction(for: CurationFeature.self)
public struct CurationView: View {
  public let store: StoreOf<CurationFeature>

  public init(store: StoreOf<CurationFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header()
      ScrollView(showsIndicators: false) {
        VStack(spacing: 16) {
          if store.isLoading, store.battles.isEmpty {
            CurationSkeletonView()
          } else if store.battles.isEmpty {
            emptyState()
          } else {
            ForEach(store.battles) { battle in
              battleCard(battle)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
  }
}

// MARK: - Header

private extension CurationView {
  @ViewBuilder
  func header() -> some View {
    HStack(spacing: 0) {
      Button { send(.backButtonTapped) } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .regular))
          .frame(width: 24, height: 24)
          .foregroundStyle(.neutral900)
      }
      .buttonStyle(.plain)

      Spacer()

      Text("더 흥미로운 배틀도 있어요!")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.neutral500)

      Spacer()

      Button { send(.closeButtonTapped) } label: {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .regular))
          .frame(width: 24, height: 24)
          .foregroundStyle(.neutral900)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.beige200)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }
}

// MARK: - Empty

private extension CurationView {
  @ViewBuilder
  func emptyState() -> some View {
    VStack(spacing: 8) {
      Image(systemName: "tray")
        .font(.system(size: 28, weight: .regular))
        .foregroundStyle(.neutral300)
      Text("추천할 배틀이 없어요")
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.neutral300)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 80)
  }
}

// MARK: - Battle Card

private extension CurationView {
  @ViewBuilder
  func battleCard(_ battle: RecommendedBattle) -> some View {
    Button { send(.battleTapped(battleId: battle.battleId)) } label: {
      VStack(alignment: .leading, spacing: 16) {
        cardMeta(battle)
        cardVersus(battle)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .stroke(.beige600, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func cardMeta(_ battle: RecommendedBattle) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        if let tag = battle.tags.first {
          Text("#\(tag.name)")
            .pretendardFont(family: .SemiBold, size: 12)
            .foregroundStyle(.primary500)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
        }

        Spacer()

        HStack(spacing: 2) {
          Image(systemName: "clock")
            .font(.system(size: 11, weight: .regular))
          Text(durationText(battle.audioDuration))
            .pretendardFont(family: .Medium, size: 12)
        }
        .foregroundStyle(.neutral300)

        HStack(spacing: 2) {
          Image(systemName: "eye")
            .font(.system(size: 11, weight: .regular))
          Text("\(battle.viewCount)")
            .pretendardFont(family: .Medium, size: 12)
        }
        .foregroundStyle(.neutral300)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(battle.title)
          .pretendardFont(family: .SemiBold, size: 14)
          .foregroundStyle(.neutral500)
          .lineSpacing(14 * 0.3)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)

        if !battle.summary.isEmpty {
          Text(battle.summary)
            .pretendardFont(family: .Medium, size: 12)
            .foregroundStyle(.neutral200)
            .lineSpacing(12 * 0.4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  @ViewBuilder
  func cardVersus(_ battle: RecommendedBattle) -> some View {
    HStack(spacing: 8) {
      optionButton(battle.options[safe: 0])
      versusBadge()
      optionButton(battle.options[safe: 1])
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func optionButton(_ option: RecommendedBattleOption?) -> some View {
    HStack(spacing: 4) {
      CommentAvatarView(
        imageURL: option?.imageUrl,
        fallback: option?.representative ?? "",
        size: 40
      )

      VStack(spacing: 2) {
        Text(option?.title ?? "")
          .pretendardFont(family: .SemiBold, size: 11)
          .foregroundStyle(.neutral500)
        Text(option?.representative ?? "")
          .pretendardFont(family: .Regular, size: 10)
          .foregroundStyle(.neutral300)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(8)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
    .overlay {
      RoundedRectangle(cornerRadius: 2)
        .stroke(.beige600, lineWidth: 1)
    }
  }

  @ViewBuilder
  func versusBadge() -> some View {
    Text("VS")
      .pretendardFont(family: .Bold, size: 8)
      .foregroundStyle(.neutral900)
      .frame(width: 24, height: 24)
      .background(.secondary200, in: Circle())
  }

  func durationText(_ seconds: Int) -> String {
    let minutes = max(1, Int((Double(seconds) / 60).rounded()))
    return "\(minutes)분"
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
