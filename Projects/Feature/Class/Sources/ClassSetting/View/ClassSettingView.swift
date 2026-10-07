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
          Text("운영 목적에 맞게\n클래스를 설정해 주세요")
            .pretendardFont(.semiBold24)
            .lineSpacing(2.4)
            .foregroundStyle(.gray500)

          nameSection()
          deadlineSection()
          contentSection()
          commentToggle
          ownerParticipationToggle
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
    .toolbar(.hidden, for: .navigationBar)
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
    .pickeModal(
      $store.scope(state: \.unavailableNotice, action: \.unavailableNotice),
      dimOpacity: 0.28
    ) { noticeStore in
      unavailableNotice(store: noticeStore)
    }
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
          .font(
            .pretendardFontFamily(
              family: .Medium,
              size: 13
            )
          )
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
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionLabel(store.aiQuestion == nil ? "선택한 배틀" : "선택한 질문")
      if let question = store.aiQuestion {
        ClassSelectedAIQuestionCard(question: question)
      } else if let battle = store.battle {
        ClassSelectedBattleCard(battle: battle)
      }
    }
  }

  var commentToggle: some View {
    Toggle(isOn: $store.requiresComment) {
      VStack(alignment: .leading, spacing: 2) {
        sectionLabel("댓글 달기 필수")
        Text("멤버의 생각을 댓글로 확인해요.")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray300)
      }
    }
    .toggleStyle(.picke)
  }

  var ownerParticipationToggle: some View {
    Toggle(isOn: .constant(false)) {
      VStack(alignment: .leading, spacing: 2) {
        sectionLabel("운영자 참여")
        Text("운영자도 콘텐츠에 참여해요.")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray300)
      }
    }
    .toggleStyle(.picke)
    .disabled(true)
    .accessibilityHint("운영자 참여 기능은 준비 중입니다")
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

  func unavailableNotice(store: StoreOf<ClassAIUnavailableNoticeFeature>) -> some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { store.send(.dismissTapped) }

      VStack(alignment: .leading, spacing: 20) {
        Capsule()
          .fill(Color.beige700)
          .frame(width: 36, height: 4)
          .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: 8) {
          Text("AI 질문 클래스 준비 중")
            .pretendardFont(.semiBold24)
            .foregroundStyle(.gray800)
          Text("지금은 예시 질문을 살펴볼 수 있어요. AI 질문으로 클래스 만들기는 아직 사용할 수 없습니다.")
            .pretendardFont(.medium15)
            .foregroundStyle(.gray300)
        }

        Button { store.send(.dismissTapped) } label: {
          Text("확인")
        }
        .ctaButtonStyle(.primary, size: .large, height: 52)
      }
      .padding(.top, 12)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
      .frame(maxWidth: .infinity)
      .background(
        UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
          .fill(.beige50)
          .ignoresSafeArea(edges: .bottom)
      )
    }
  }
}
