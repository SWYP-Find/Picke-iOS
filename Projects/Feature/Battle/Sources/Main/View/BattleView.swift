//
//  BattleView.swift
//  Battle
//

import SwiftUI

import ComposableArchitecture
import PickeSharedUI
import PickeDesignKit

@ViewAction(for: BattleFeature.self)
public struct BattleView: View {
  @Bindable public var store: StoreOf<BattleFeature>
  /// 현재 보이는 배틀 (세로 페이징) — 공유 시 대상 식별.
  @State private var currentBattleId: Int?

  public init(store: StoreOf<BattleFeature>) {
    self.store = store
  }

  /// 현재 보이는 배틀의 인덱스 (상단 paging 바 채움 기준). 스크롤 전엔 0.
  private var currentPageIndex: Int {
    guard let id = currentBattleId,
          let index = store.battles.firstIndex(where: { $0.id == id })
    else { return 0 }
    return index
  }

  public var body: some View {
    // ZStack 은 safe-area 존중(ignoresSafeArea 미적용) → appBar 가 노치 아래 + 항상 최상단 탭 가능.
    // 배경/pager 는 각자 내부에서 ignoresSafeArea 로 풀블리드 유지.
    ZStack {
      Color.neutral900.ignoresSafeArea()

      if store.viewState == .loading {
        BattleSkeletonView()
      } else if store.battles.isEmpty {
        emptyState()
      } else {
        pager()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // PreVoteView 패턴: 상단 paging 바 + 앱바를 overlay 로 올려 항상 최상단·탭 가능하게.
    .overlay(alignment: .top) {
      VStack(spacing: 14) {
        // 배틀이 여러 건일 때만 상단 paging 바 노출. 터치 시 해당 배틀로 이동.
        if store.battles.count > 1 {
          BattlePagingBar(
            pageCount: store.battles.count,
            currentIndex: currentPageIndex,
            onSelect: { index in
              guard store.battles.indices.contains(index) else { return }
              let id = store.battles[index].id
              send(.pagingTapped(index: index))
              withAnimation(.easeInOut(duration: 0.25)) { currentBattleId = id }
            }
          )
        }
        appBar()
      }
      .padding(.top, 10)
      .zIndex(10)
    }
    .navigationBarHidden(true)
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
    // 데이터 로드 후 첫 페이지를 현재 배틀로 초기화 (스크롤 전엔 scrollPosition 이 nil).
    .onChange(of: store.battles.map(\.id)) { _, ids in
      if currentBattleId == nil { currentBattleId = ids.first }
    }
    .sheet(item: $store.shareItem) { item in
      ShareSheet(items: item.items)
        .presentationDetents([.fraction(0.5)])
    }
  }
}

// MARK: - Pager (세로 페이징)

private extension BattleView {
  @ViewBuilder
  func pager() -> some View {
    GeometryReader { proxy in
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 0) {
          ForEach(store.battles) { battle in
            battlePage(battle, size: proxy.size)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $currentBattleId)
      .scrollDisabled(store.battles.count <= 1)
    }
    .ignoresSafeArea()
  }

  // PreVoteView 패턴: 배경 이미지와 콘텐츠 각각에 proxy 폭을 명시해 폭을 제약한다.
  @ViewBuilder
  func battlePage(_ battle: DailyBattle, size: CGSize) -> some View {
    ZStack(alignment: .bottom) {
      backgroundImage(battle.imageURL)
        .frame(width: size.width, height: size.height)

      bottomContent(battle)
        .frame(width: size.width)
    }
    .frame(width: size.width, height: size.height)
  }
}

// MARK: - Background

private extension BattleView {
  @ViewBuilder
  func backgroundImage(_ imageURL: String?) -> some View {
    ZStack {
      if let imageURL, let url = URL(string: imageURL) {
        PickeRemoteImage(url: url) { Color.neutral800 }
      } else {
        Color.neutral800
      }

      LinearGradient(
        stops: [
          .init(color: .neutral900.opacity(0), location: 0),
          .init(color: .neutral900.opacity(0.85), location: 0.55),
          .init(color: .neutral900, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
  }
}

// MARK: - App Bar

private extension BattleView {
  @ViewBuilder
  func appBar() -> some View {
    PickeNavigationBar(onBack: { send(.backTapped) }) {
      // 데이터 없을 땐 공유 숨김.
      if let battleId = currentBattleId ?? store.battles.first?.battleId {
        Button { send(.shareTapped(battleId: battleId)) } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
      }
    }
    .foregroundStyle(.beige50)
    .contentShape(Rectangle())
  }
}

// MARK: - Bottom Content

private extension BattleView {
  @ViewBuilder
  func bottomContent(_ battle: DailyBattle) -> some View {
    VStack(spacing: 32) {
      contentSection(battle)
      vsOptions(battle)
      enterButton(battle)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
  }

  @ViewBuilder
  func contentSection(_ battle: DailyBattle) -> some View {
    VStack(spacing: 16) {
      VStack(spacing: 12) {
        VStack(spacing: 20) {
          tagsRow(battle.tags)
          Text(battle.title)
            .pretendardFont(.bold24)
            .foregroundStyle(.beige50)
            .kerning(-0.6)
            .multilineTextAlignment(.center)
            .lineSpacing(24 * 0.18)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
        }

        if !battle.question.isEmpty {
          Text(battle.question)
            .pretendardFont(.bodyMedium)
            .foregroundStyle(.gray300)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      durationBadge(battle.durationText)
    }
  }

  @ViewBuilder
  func tagsRow(_ tags: [String]) -> some View {
    HStack(spacing: 9) {
      ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
        Text("#\(tag)")
          .pickeBadge(.filled, size: .tag)
      }
    }
  }

  @ViewBuilder
  func durationBadge(_ text: String) -> some View {
    HStack(spacing: 4) {
      Image(systemName: "clock")
        .font(.system(size: 11, weight: .semibold))
      Text(text)
        .pretendardFont(.semiBold12)
    }
    .foregroundStyle(.gray300)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .roundedBorder(.gray500)
  }
}

// MARK: - VS Options (세로 카드 + VS 배지)

private extension BattleView {
  @ViewBuilder
  func vsOptions(_ battle: DailyBattle) -> some View {
    let options = battle.options
    let selectedId = store.selectedOptionByBattle[battle.battleId]
    ZStack {
      VStack(spacing: 12) {
        ForEach(options) { option in
          optionCard(option, isSelected: selectedId == option.id) {
            send(.optionTapped(battleId: battle.battleId, optionId: option.id))
          }
        }
      }

      if options.count > 1 {
        vsBadge()
      }
    }
  }

  /// 선택 시 picke.pen 강조(neutral900 배경 + 골드 테두리), 미선택은 gray700.
  @ViewBuilder
  func optionCard(
    _ option: DailyBattle.Option,
    isSelected: Bool,
    onTap: @escaping () -> Void
  ) -> some View {
    Button(action: onTap) {
      VStack(spacing: 0) {
        Text(option.representative)
          .pretendardFont(.bold10)
          .foregroundStyle(.secondary500)
          .kerning(1.5)
          .padding(.bottom, 8)

        Text(option.stance)
          .pretendardFont(.bold18)
          .foregroundStyle(.beige50)
          .kerning(-0.45)
          .multilineTextAlignment(.center)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .padding(.horizontal, 20)

        if !option.quote.isEmpty {
          Text(option.quote)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.gray300)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
      .pickeCard(isSelected ? .neutral900 : .gray700, border: isSelected ? .secondary500 : .clear)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func vsBadge() -> some View {
    Text("VS")
      .pretendardFont(.headingSmall)
      .foregroundStyle(.neutral900)
      .frame(width: 40, height: 40)
      .background(.secondary200, in: Circle())
      .overlay(Circle().stroke(.beige50, lineWidth: 1.5))
  }
}

// MARK: - CTA

private extension BattleView {
  @ViewBuilder
  func enterButton(_ battle: DailyBattle) -> some View {
    Button("배틀 입장하기") { send(.enterBattleTapped(battleId: battle.battleId)) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(store.selectedOptionByBattle[battle.battleId] == nil)
  }
}

// MARK: - Empty / Skeleton

private extension BattleView {
  @ViewBuilder
  func emptyState() -> some View {
    VStack(spacing: 8) {
      Image(asset: .noDataLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 135, height: 90)

      Text("아직 빠른 배틀이 선정되지 않았어요\n 조금만 기다려주세요!")
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.beige300)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
