//
//  ClassStartMethodView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassStartMethodFeature.self)
public struct ClassStartMethodView: View {
  @Bindable public var store: StoreOf<ClassStartMethodFeature>

  public init(store: StoreOf<ClassStartMethodFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar
      contentSection()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .accessibilityHidden(store.guide != nil)
    .allowsHitTesting(store.guide == nil)
    .pickeModal(
      $store.scope(state: \.guide, action: \.guide),
      dimOpacity: 0.28
    ) { guideStore in
      ClassStartGuideView(store: guideStore)
    }
  }
}

private extension ClassStartMethodView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: "새 클래스 만들기"
    )
    .foregroundStyle(.gray500)
  }

  @ViewBuilder
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      titleSection()
        .padding(.bottom, 32)

      methodCards()

      Spacer(minLength: 16)

      continueButton
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 16)
  }

  @ViewBuilder
  func methodCards() -> some View {
    VStack(spacing: 16) {
      methodCard(
        .existingContent,
        guide: .pickeBattle,
        badge: "TTS 포함",
        title: "Pické 배틀로 클래스 만들기",
        description: "기존 배틀 콘텐츠를 골라 클래스를 만들어요"
      )
      methodCard(
        .ownTopic,
        guide: .customBattle,
        badge: "AI 채팅",
        title: "커스텀 배틀로 클래스 만들기",
        description: "원하는 주제로 직접 배틀을 만들어보세요"
      )
    }
  }

  var continueButton: some View {
    Button { send(.continueTapped) } label: {
      Text("주제 정하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("어떤 방식으로\n클래스를 만들까요?")
        .pretendardFont(.semiBold24)
        .lineSpacing(2.4)
        .foregroundStyle(.gray800)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 62, alignment: .topLeading)

      Text("준비된 콘텐츠를 쓰거나, 내 주제로 직접 시작할 수 있어요")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 23, alignment: .leading)
    }
  }

  func methodCard(
    _ method: ClassStartMethodFeature.Method,
    guide: ClassStartGuideKind,
    badge: String,
    title: String,
    description: String
  ) -> some View {
    let selected = store.selectedMethod == method

    return Button { send(.methodTapped(method)) } label: {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 8) {
          methodBadge(badge, guide: guide)

          Text(title)
            .pretendardFont(.headingMedium)
            .foregroundStyle(.gray800)

          Text(description)
            .pretendardFont(.bodySmall)
            .foregroundStyle(.gray400)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 0)

        Image(systemName: "checkmark")
          .pickeCheckbox(isChecked: selected, size: 24)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .frame(height: 120)
      .pickeCard(.beige50, border: selected ? .primary500 : .beige600, radius: 0)
    }
    .buttonStyle(.plain)
    .overlayPreferenceValue(ClassStartInfoAnchorPreferenceKey.self) { anchors in
      GeometryReader { geometry in
        if let anchor = anchors[guide] {
          let icon = geometry[anchor]
          Button { send(.guideTapped(guide)) } label: {
            Image(systemName: "info.circle")
              .resizable()
              .scaledToFit()
              .frame(width: 14, height: 14)
              .foregroundStyle(.primary500)
              .frame(width: 44, height: 44, alignment: .bottomLeading)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(guide == .pickeBattle ? "Pické 배틀 이용 가이드" : "커스텀 배틀 이용 가이드")
          .position(x: icon.minX + 22, y: icon.maxY - 22)
        }
      }
    }
  }

  @ViewBuilder
  func methodBadge(
    _ title: String,
    guide: ClassStartGuideKind
  ) -> some View {
    HStack(spacing: 4) {
      Text(title)
      Image(systemName: "info.circle")
        .resizable()
        .scaledToFit()
        .frame(width: 14, height: 14)
        .opacity(0)
        .accessibilityHidden(true)
        .anchorPreference(key: ClassStartInfoAnchorPreferenceKey.self, value: .bounds) { [guide: $0] }
    }
    .pretendardFont(.labelSmall)
    .foregroundStyle(.primary500)
    .padding(.horizontal, 9)
    .padding(.vertical, 4)
    .background(.primary50, in: Capsule())
  }
}
