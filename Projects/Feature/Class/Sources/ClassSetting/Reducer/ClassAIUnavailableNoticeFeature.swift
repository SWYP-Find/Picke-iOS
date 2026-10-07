//
//  ClassAIUnavailableNoticeFeature.swift
//  Class
//

import ComposableArchitecture

@Reducer
public struct ClassAIUnavailableNoticeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case dismissTapped
  }

  public var body: some Reducer<State, Action> {
    EmptyReducer()
  }
}
