//
//  HifiFeature.swift
//  Hifi
//
//  Hi-Fi 탭 루트 기능. 기본 골격만 구성 (추후 화면 구현 시 State/Action 확장).
//

import Foundation

import ComposableArchitecture

@Reducer
public struct HifiFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
  }

  public enum DelegateAction: Equatable {}

  public var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case .view(.onAppear):
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
