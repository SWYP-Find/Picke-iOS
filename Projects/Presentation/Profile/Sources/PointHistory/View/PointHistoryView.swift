//
//  PointHistoryView.swift
//  Profile
//
//  포인트(크레딧) 내역 UI — picke.pen `포인트 내역`.
//  App Bar(백/타이틀) + 내역 리스트(좌: 유형·날짜 / 우: 금액·적립·사용).
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Entity
import Utill

@ViewAction(for: PointHistoryFeature.self)
public struct PointHistoryView: View {
  @Bindable public var store: StoreOf<PointHistoryFeature>

  public init(store: StoreOf<PointHistoryFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      appBar()

      if store.isLoading {
        PointHistorySkeletonView()
      } else {
        content()
      }
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
    .onAppear { send(.onAppear) }
  }
}

private extension PointHistoryView {
  // MARK: App Bar

  @ViewBuilder
  func appBar() -> some View {
    PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "포인트 내역") {
      // 배틀(주제) 제안 팝업 열기
      Button { send(.suggestTopicTapped) } label: {
        Image(asset: .history)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
      }
    }
    .foregroundStyle(.gray500)
  }

  // MARK: 내역 리스트

  @ViewBuilder
  func content() -> some View {
    if store.items.isEmpty {
      emptyState()
    } else {
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(store.items) { item in
            historyRow(item)
              .onAppear {
                if item.id == store.items.last?.id {
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
  func historyRow(_ item: CreditHistoryItem) -> some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(item.title)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral900)

        Text(item.createdAt.yearMonthDayDot)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 6) {
        Text(item.amountText)
          .pretendardFont(.headingSmall)
          .foregroundStyle(item.isEarned ? .primary500 : .gray500)

        Text(item.statusText)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.gray300)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .roundedBackground(.beige50, radius: 8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(.beige600, lineWidth: 1)
    )
  }

  @ViewBuilder
  func emptyState() -> some View {
    PickeEmptyStateView(message: "포인트 내역이 없어요")
  }
}
