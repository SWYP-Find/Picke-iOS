//
//  ClassRecommendView.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassRecommendFeature.self)
public struct ClassRecommendView: View {
  @Bindable public var store: StoreOf<ClassRecommendFeature>

  public init(store: StoreOf<ClassRecommendFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "추천 배틀"
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          introSection()
          resultSection()
        }
        .padding(.bottom, 148)
      }
      .scrollIndicators(.hidden)
    }
    .overlay(alignment: .bottom) {
      bottomSection()
    }
    .screenBackground()
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
  }
}

private extension ClassRecommendView {
  @ViewBuilder
  func introSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text("수업에 어울리는\n배틀을 찾았어요")
          .pretendardFont(.semiBold24)
          .lineSpacing(7)
          .foregroundStyle(.gray800)

        Text("미리 듣고 클래스에 사용할 배틀을 골라보세요.")
          .pretendardFont(.medium15)
          .foregroundStyle(.gray300)
      }

      conditionRow()
    }
    .padding(16)
  }

  @ViewBuilder
  func conditionRow() -> some View {
    HStack(spacing: 8) {
      Text("선택한 조건")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)

      HStack(spacing: 6) {
        ForEach(store.conditionTitles, id: \.self) {
          Text($0).pickePill()
        }
      }

      Spacer(minLength: 0)

      Button {
        send(.editConditionTapped)
      } label: {
        Text("조건 수정")
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  func resultSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(store.resultTitle)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.gray800)

      ForEach(store.battles) { battle in
        ClassBattleListCard(
          battle: battle,
          isSelected: store.selectedBattleId == battle.id,
          onPreview: { send(.previewTapped(battle.id)) }
        )
        .onTapGesture { send(.battleTapped(battle.id)) }
      }
    }
    .padding([.horizontal, .top], 16)
  }

  @ViewBuilder
  func bottomSection() -> some View {
    VStack(spacing: 0) {
      LinearGradient(
        colors: [.beige200.opacity(0), .beige200],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 70)
      .allowsHitTesting(false)

      selectButton
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
        .background(.beige200)
    }
  }

  var selectButton: some View {
    Button {
      send(.selectTapped)
    } label: {
      Text("배틀 선택하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canSelect)
  }
}
