//
//  ClassSettingView.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassSettingFeature.self)
public struct ClassSettingView: View {
  @Bindable public var store: StoreOf<ClassSettingFeature>

  public init(store: StoreOf<ClassSettingFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "클래스 설정"
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          Text("수업 정보에 맞게\n클래스를 설정해 주세요")
            .pretendardFont(.semiBold24)
            .lineSpacing(2.4)
            .foregroundStyle(.gray500)

          nameSection()
          deadlineSection()
          battleSection()
          commentToggle
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)

      createButton
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .hidesSystemBars()
  }
}

private extension ClassSettingView {
  @ViewBuilder
  func nameSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("클래스 명")

      TextField(
        "",
        text: $store.name,
        prompt: Text("ex) 2학년 3반 1학기 토론")
          .foregroundStyle(.gray300)
      )
      .pickeTextField()
    }
  }

  @ViewBuilder
  func deadlineSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Toggle(isOn: $store.isDeadlineEnabled) {
        VStack(alignment: .leading, spacing: 2) {
          sectionLabel("참여 마감일")
          Text("마감 전까지 학생이 클래스에 참여할 수 있어요.")
            .pretendardFont(.bodySmall)
            .foregroundStyle(.gray300)
        }
      }
      .toggleStyle(.picke)

      if store.isDeadlineEnabled {
        deadlineField
      }

      if store.isDeadlineEnabled, store.isDatePickerPresented {
        DatePicker(
          "",
          selection: $store.deadline,
          in: Date()...,
          displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.graphical)
        .tint(.primary500)
        .pickeCard(.beige50, border: .beige600)
      }
    }
  }

  var deadlineField: some View {
    Button {
      send(.deadlineFieldTapped)
    } label: {
      Text(store.deadlineText)
        .pretendardFont(.labelMedium)
        .foregroundStyle(.gray800)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .pickeCard(.beige50, border: .beige600)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func battleSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionLabel("선택한 배틀")
      ClassSelectedBattleCard(battle: store.battle)
    }
  }

  var commentToggle: some View {
    Toggle(isOn: $store.requiresComment) {
      VStack(alignment: .leading, spacing: 2) {
        sectionLabel("댓글 달기 필수")
        Text("학생들의 생각을 댓글로 확인해요.")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray300)
      }
    }
    .toggleStyle(.picke)
  }

  func sectionLabel(_ title: String) -> some View {
    Text(title)
      .pretendardFont(.semiBold15)
      .foregroundStyle(.gray800)
  }

  var createButton: some View {
    Button {
      send(.createTapped)
    } label: {
      Text("클래스 만들기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canCreate)
  }
}
