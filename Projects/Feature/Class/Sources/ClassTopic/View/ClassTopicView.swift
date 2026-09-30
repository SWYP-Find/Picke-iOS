//
//  ClassTopicView.swift
//  Class
//

import SwiftUI

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit

@ViewAction(for: ClassTopicFeature.self)
public struct ClassTopicView: View {
  @Bindable public var store: StoreOf<ClassTopicFeature>

  public init(store: StoreOf<ClassTopicFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "새 클래스 만들기"
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          titleSection()
          formSection()
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)

      searchButton()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .hidesSystemBars()
  }
}

private extension ClassTopicView {
  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("어떤 주제로\n이야기 나눌까요?")
        .pretendardFont(.semiBold24)
        .lineSpacing(7)
        .foregroundStyle(.gray800)

      Text("관심 있는 주제나 수업 조건을 선택해 주세요.")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func formSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      field("찾고 싶은 주제") {
        PickeTextField(
          "예) 촉법소년 · AI가 인간의 일을 대신해도 될까?",
          text: $store.keyword
        )
      }

      field("대상 수준") {
        PickeBoxSegment(
          ClassAudienceLevel.allCases,
          selection: $store.level,
          title: \.title
        )
      }

      field("카테고리") {
        categoryGrid()
      }
    }
  }

  @ViewBuilder
  func field(
    _ label: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(label)
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)
      content()
    }
  }

  @ViewBuilder
  func categoryGrid() -> some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
      spacing: 8
    ) {
      ForEach(ClassCategory.allCases, id: \.self) { category in
        Button {
          send(.categoryTapped(category))
        } label: {
          Text(category.title)
            .pickeChoiceChip(isSelected: store.category == category)
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  func searchButton() -> some View {
    Button {
      send(.searchTapped)
    } label: {
      Text("조건에 맞는 콘텐츠 보기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
  }
}
