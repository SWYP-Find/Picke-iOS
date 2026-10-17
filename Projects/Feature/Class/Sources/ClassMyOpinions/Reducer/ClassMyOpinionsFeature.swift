//
//  ClassMyOpinionsFeature.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassMyOpinionsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var opinions: [ClassReportOpinion] = []

    public var comments: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .comment }
    }

    public var replies: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .reply }
    }

    public var unspecified: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .unspecified }
    }

    public var isEmpty: Bool { opinions.isEmpty }

    private var rows: [ClassMyOpinionRow] {
      opinions.enumerated().map { ClassMyOpinionRow(index: $0.offset, opinion: $0.element) }
    }

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case .view(.backTapped):
        return .send(.delegate(.dismiss))
      case .delegate:
        return .none
      }
    }
  }
}
