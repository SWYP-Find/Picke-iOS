//
//  TermsAgreementFeature.swift
//  Auth
//

import Foundation

import ComposableArchitecture
import AuthDomainInterface

@Reducer
public struct TermsAgreementFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var agreed: Set<TermsDocument> = []

    /// 필수 약관 모두 동의 시 true.
    public var canAgree: Bool {
      TermsDocument.requiredCases.allSatisfy { agreed.contains($0) }
    }

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case toggled(TermsDocument)
    case detailTapped(TermsDocument)
    case agreeTapped
    case dismissTapped
  }

  public enum DelegateAction: Equatable {
    case confirmed
    case dismissed
    /// 약관 상세 보기 — 부모가 WebView 로 표시.
    case openDocument(TermsDocument)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(.toggled(document)):
        if state.agreed.contains(document) {
          state.agreed.remove(document)
        } else {
          state.agreed.insert(document)
        }
        return .none

      case let .view(.detailTapped(document)):
        return .send(.delegate(.openDocument(document)))

      case .view(.agreeTapped):
        guard state.canAgree else { return .none }
        return .send(.delegate(.confirmed))

      case .view(.dismissTapped):
        return .send(.delegate(.dismissed))

      case .delegate:
        return .none
      }
    }
  }
}
