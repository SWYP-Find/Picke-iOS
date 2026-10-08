//
//  ClassTopicView.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassTopicFeature.self)
public struct ClassTopicView: View {
  @Bindable public var store: StoreOf<ClassTopicFeature>
  @Namespace private var levelNamespace

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

      searchButton
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassTopicView {
  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("어떤 주제로\n이야기 나눌까요?")
        .pretendardFont(.semiBold24)
        .lineSpacing(2.4)
        .foregroundStyle(.gray800)

      Text("관심 있는 주제나 배틀 조건을 선택해 주세요.")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func formSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      field("찾고 싶은 주제") {
        TextField(
          "",
          text: $store.keyword,
          prompt: Text("예) 촉법소년 · AI가 인간의 일을 대신해도 될까?")
            .foregroundStyle(.gray300)
        )
        .pickeTextField()
      }

      field("대상 수준") {
        levelSegment()
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
  func levelSegment() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassAudienceLevel.allCases, id: \.self) { level in
        Button {
          withAnimation(.snappy(duration: 0.25)) {
            store.level = level
          }
        } label: {
          Text(level.topicTitle)
            .pickeBoxSegment(
              isSelected: store.level == level,
              namespace: levelNamespace
            )
        }
        .buttonStyle(.plain)
      }
    }
    .pickeBoxSegmentTrack()
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

  var searchButton: some View {
    Button {
      send(.searchTapped)
    } label: {
      Text("조건에 맞는 콘텐츠 보기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
  }
}
