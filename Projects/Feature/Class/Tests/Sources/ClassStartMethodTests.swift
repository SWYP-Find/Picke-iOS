//
//  ClassStartMethodTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ComposableArchitecture
import PickeDesignKit
import Testing
import UIKit

@MainActor
struct ClassStartMethodTests {
  @Test
  func 기존_콘텐츠를_선택하면_주제_설정으로_넘긴다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.existingContentSelected)
  }

  @Test
  func 내_주제로_시작하면_AI_경로를_요청한다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.methodTapped(.ownTopic))) {
      $0.selectedMethod = .ownTopic
    }
    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.ownTopicSelected)
  }

  @Test
  func 뒤로_가면_화면_닫기를_요청한다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 정보_아이콘은_선택을_바꾸지_않고_각_가이드를_연다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.guideTapped(.pickeBattle))) {
      $0.guide = .showing(.pickeBattle)
    }
    #expect(store.state.selectedMethod == .existingContent)
    await store.send(.guide(.presented(.dismissTapped))) {
      $0.guide = nil
    }

    await store.send(.view(.guideTapped(.customBattle))) {
      $0.guide = .showing(.customBattle)
    }
    #expect(store.state.selectedMethod == .existingContent)
    await store.send(.guide(.presented(.dismissTapped))) {
      $0.guide = nil
    }
    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.existingContentSelected)
  }

  @Test
  func 가이드가_열리면_카드_선택과_다음_화면은_막고_뒤로는_가이드를_닫는다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.guideTapped(.customBattle))) {
      $0.guide = .showing(.customBattle)
    }
    await store.send(.view(.methodTapped(.ownTopic)))
    await store.send(.view(.continueTapped))
    await store.send(.view(.guideTapped(.pickeBattle)))
    #expect(store.state.guide?.kind == .customBattle)
    #expect(store.state.selectedMethod == .existingContent)

    await store.send(.view(.backTapped)) {
      $0.guide = nil
    }
    await store.send(.view(.methodTapped(.ownTopic))) {
      $0.selectedMethod = .ownTopic
    }
    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.ownTopicSelected)
  }

  @Test
  func 시스템_시트_닫기도_가이드만_해제한다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.guideTapped(.pickeBattle))) {
      $0.guide = .showing(.pickeBattle)
    }
    await store.send(.guide(.dismiss)) {
      $0.guide = nil
    }
    #expect(store.state.selectedMethod == .existingContent)
  }

  @Test
  func 두_가이드는_각각의_문구와_원본_삽화를_사용한다() {
    let picke = ClassStartGuideFeature.State.showing(.pickeBattle)
    let custom = ClassStartGuideFeature.State.showing(.customBattle)

    #expect(picke.title == "Pické 배틀 이용 가이드")
    #expect(picke.headline == "준비된 콘텐츠와 오디오로 바로 토론해요")
    #expect(picke.description == "서로 다른 의견을 들으며 주제에 대한 관점을 비교해요.")
    #expect(picke.illustration == .classPickeBattleGuide)
    #expect(custom.title == "커스텀 배틀 이용 가이드")
    #expect(custom.headline == "우리만의 주제로 AI와 토론해요")
    #expect(custom.description == "반대 입장의 AI 철학자와 대화를 나누며 생각을 확장해요.")
    #expect(custom.illustration == .classCustomBattleGuide)
    #expect(UIImage(picke.illustration) != nil)
    #expect(UIImage(custom.illustration) != nil)
  }
}
