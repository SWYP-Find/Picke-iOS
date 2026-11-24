//
//  ClassStartGuideFeature.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ComposableArchitecture
import PickeDesignKit

@Reducer
public struct ClassStartGuideFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var kind: ClassStartGuideKind = .pickeBattle

    public init() {}

    public static func showing(_ kind: ClassStartGuideKind) -> Self {
      var state = Self()
      state.kind = kind
      return state
    }

    public var title: String {
      switch kind {
      case .pickeBattle: return "Pické 배틀 이용 가이드"
      case .customBattle: return "커스텀 배틀 이용 가이드"
      }
    }

    public var headline: String {
      switch kind {
      case .pickeBattle: return "준비된 콘텐츠와 오디오로 바로 토론해요"
      case .customBattle: return "우리만의 주제로 AI와 토론해요"
      }
    }

    public var description: String {
      switch kind {
      case .pickeBattle: return "서로 다른 의견을 들으며 주제에 대한 관점을 비교해요."
      case .customBattle: return "반대 입장의 AI 철학자와 대화를 나누며 생각을 확장해요."
      }
    }

    public var illustration: ImageAsset {
      switch kind {
      case .pickeBattle: return .classPickeBattleGuide
      case .customBattle: return .classCustomBattleGuide
      }
    }
  }

  public enum Action {
    case dismissTapped
  }

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
