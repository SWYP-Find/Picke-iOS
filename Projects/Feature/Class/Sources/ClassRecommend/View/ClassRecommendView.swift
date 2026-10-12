//
//  ClassRecommendView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
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
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension ClassRecommendView {
  @ViewBuilder
  func introSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text(store.introTitle)
          .pretendardFont(.semiBold24)
          .lineSpacing(2.4)
          .foregroundStyle(.gray800)
          .fixedSize(horizontal: false, vertical: true)
          .frame(minHeight: 62, alignment: .topLeading)

        Text(store.introDescription)
          .pretendardFont(.medium15)
          .foregroundStyle(.gray300)
          .fixedSize(horizontal: false, vertical: true)
          .frame(minHeight: 23, alignment: .leading)
      }

      conditionRow()
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, store.mode == .aiQuestions ? 16 : 0)
  }

  @ViewBuilder
  func conditionRow() -> some View {
    HStack(spacing: 12) {
      Text("선택한 조건")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)

      ScrollView(.horizontal) {
        HStack(spacing: 6) {
          ForEach(Array(store.conditionTitles.enumerated()), id: \.offset) { item in
            Text(item.element)
              .frame(minHeight: 17)
              .pickePill()
          }
        }
        .padding(.trailing, 60)
      }
      .scrollIndicators(.hidden)
    }
    .frame(height: 36)
    .overlay(alignment: .trailing) {
      LinearGradient(
        colors: [.beige200.opacity(0), .beige200],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: 60, height: 32)
      .allowsHitTesting(false)
    }
    .overlay(alignment: .trailing) {
      Button {
        send(.editConditionTapped)
      } label: {
        Image(asset: .classConditionReset)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)
          .frame(width: 36, height: 36)
          .background(.beige50, in: Circle())
          .overlay(Circle().strokeBorder(.primary100, lineWidth: 1))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("조건 수정")
    }
  }

  @ViewBuilder
  func resultSection() -> some View {
    Group {
      switch store.viewState {
      case .error:
        PickeRetryErrorView(message: "추천 배틀을 불러오지 못했어요") { send(.retryTapped) }
          .frame(maxWidth: .infinity, minHeight: 160)
      case .loading:
        ClassRecommendSkeletonView()
      case .empty, .loaded:
        resultList()
      }
    }
    .padding([.horizontal, .top], 16)
  }

  @ViewBuilder
  func resultList() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(store.resultTitle)
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray800)
        Spacer()
        if store.mode == .aiQuestions {
          Button { send(.recommendAgainTapped) } label: {
            Label("다시 추천", systemImage: "arrow.clockwise")
              .pretendardFont(.medium13)
              .foregroundStyle(.gray300)
          }
          .buttonStyle(.plain)
        }
      }
      .frame(minHeight: 20)

      if store.mode == .aiQuestions {
        ForEach(store.questions) { question in
          ClassAIQuestionCard(
            question: question,
            isSelected: store.selectedQuestionId == question.id
          )
          .onTapGesture { send(.questionTapped(question.id)) }
        }
      } else {
        ForEach(store.battles) { battle in
          ClassBattleListCard(
            battle: battle,
            isSelected: store.selectedBattleId == battle.id,
            onPreview: { send(.previewTapped(battle.id)) }
          )
          .onTapGesture { send(.battleTapped(battle.id)) }
        }
      }
    }
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
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(.beige200)
    }
  }

  var selectButton: some View {
    Button {
      send(.selectTapped)
    } label: {
      Text(store.selectButtonTitle)
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canSelect)
  }
}
