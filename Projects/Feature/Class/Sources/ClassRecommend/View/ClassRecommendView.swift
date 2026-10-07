//
//  ClassRecommendView.swift
//  Class
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
        Text(store.mode == .aiQuestions ? "AI가 주제에 어울리는\n질문을 만들었어요" : "주제에 어울리는\n배틀을 찾았어요")
          .pretendardFont(.semiBold24)
          .lineSpacing(2.4)
          .foregroundStyle(.gray800)

        Text(store.mode == .aiQuestions ? "예시 질문을 골라 클래스를 설정해 주세요." : "미리 듣고 클래스에 사용할 배틀을 골라보세요.")
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
        .padding(.horizontal, 12)
        .background(.beige200)
    }
  }

  var selectButton: some View {
    Button {
      send(.selectTapped)
    } label: {
      Text(store.mode == .aiQuestions ? "질문 선택하기" : "배틀 선택하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canSelect)
  }
}
