//
//  ClassStartMethodView.swift
//  Class
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassStartMethodFeature.self)
public struct ClassStartMethodView: View {
  @Bindable public var store: StoreOf<ClassStartMethodFeature>

  public init(store: StoreOf<ClassStartMethodFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "새 클래스 만들기"
      )
      .foregroundStyle(.gray500)

      VStack(alignment: .leading, spacing: 0) {
        titleSection()
          .padding(.bottom, 32)

        VStack(spacing: 16) {
          methodCard(
            .existingContent,
            badge: "TTS 포함",
            title: "Pické 기존 콘텐츠로 시작",
            description: "준비된 지식 배틀을 골라 바로 클래스를 만들어요."
          )
          methodCard(
            .ownTopic,
            badge: "AI 발제 추천",
            title: "내 주제로 시작",
            description: "원하는 주제를 입력하고, 질문을 만들어보세요."
          )
        }
        .padding(.horizontal, 6)

        Spacer(minLength: 16)

        Button { send(.continueTapped) } label: {
          Text("주제 설정하기")
        }
        .ctaButtonStyle(.primary, size: .large, height: 52)
      }
      .padding(.horizontal, 16)
      .padding(.top, 24)
      .padding(.bottom, 16)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassStartMethodView {
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("어떤 방식으로\n클래스를 시작할까요?")
        .pretendardFont(.semiBold24)
        .lineSpacing(2.4)
        .foregroundStyle(.gray800)

      Text("준비된 콘텐츠를 바로 쓰거나, 내 주제로 직접 시작할 수 있어요.")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  func methodCard(
    _ method: ClassStartMethodFeature.Method,
    badge: String,
    title: String,
    description: String
  ) -> some View {
    let selected = store.selectedMethod == method

    return Button { send(.methodTapped(method)) } label: {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 8) {
          Text(badge)
            .pretendardFont(.labelSmall)
            .foregroundStyle(.primary500)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.primary50, in: Capsule())

          Text(title)
            .pretendardFont(.headingMedium)
            .foregroundStyle(.gray800)

          Text(description)
            .pretendardFont(.bodySmall)
            .foregroundStyle(.gray400)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 0)

        Image(systemName: selected ? "checkmark.circle.fill" : "circle.fill")
          .font(.system(size: 24))
          .foregroundStyle(selected ? Color.primary500 : Color.primary50)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .frame(height: 124)
      .background(Color.beige50)
      .overlay {
        Rectangle()
          .strokeBorder(selected ? Color.primary500 : Color.beige600, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }
}
