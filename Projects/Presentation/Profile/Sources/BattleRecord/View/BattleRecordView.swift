//
//  BattleRecordView.swift
//  Profile
//
//  내 배틀 기록 UI — picke.pen `내 배틀기록`.
//  App Bar + 기록 카드(뱃지/제목/요약/날짜) 리스트 + 무한 스크롤.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Utill

@ViewAction(for: BattleRecordFeature.self)
public struct BattleRecordView: View {
  @Bindable public var store: StoreOf<BattleRecordFeature>

  public init(store: StoreOf<BattleRecordFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "내 배틀 기록")
        .foregroundStyle(.gray500)

      if store.isLoading {
        BattleRecordSkeletonView()
      } else {
        content()
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .onAppear { send(.onAppear) }
  }
}

private extension BattleRecordView {
  @ViewBuilder
  func content() -> some View {
    if store.items.isEmpty {
      emptyState()
    } else {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(store.items) { record in
            recordCard(record)
              .onAppear {
                if record.id == store.items.last?.id {
                  send(.reachedBottom)
                }
              }
          }

          if store.isLoadingMore {
            ProgressView()
              .padding(.vertical, 8)
          }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
    }
  }

  @ViewBuilder
  func recordCard(_ record: BattleRecord) -> some View {
    Button {
      send(.recordTapped(record))
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          if !record.categoryTag.isEmpty {
            Text(record.categoryTag)
              .pretendardFont(.semiBold12)
              .foregroundStyle(.primary500)
              .padding(.vertical, 2)
              .padding(.horizontal, 6)
              .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
          }

          Text(record.title)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.gray500)
            .lineLimit(1)
        }

        Text(record.summary)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray400)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 6)

        Text(record.createdAt.yearMonthDayDot)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(.beige600, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func emptyState() -> some View {
    PickeEmptyStateView(message: "아직 배틀 기록이 없어요")
  }
}
