//
//  ClassMyOpinionsFeature.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassMyOpinionsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var opinions: [ClassReportOpinion] = []
    public var classID: Int?
    public var isLoading = false
    public var errorMessage: String?

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
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case retryTapped
    case backTapped
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetch
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case perspectivesResponse(Result<[ClassPerspectiveItem], ClassBattleError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public enum CancelID: Hashable, Sendable {
    case fetch
  }

  @Dependency(\.classBattleUseCase) private var classBattleUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        guard state.classID != nil, !state.isLoading, state.opinions.isEmpty, state.errorMessage == nil else { return .none }
        return .send(.async(.fetch))
      case .view(.retryTapped):
        guard state.classID != nil, !state.isLoading else { return .none }
        return .send(.async(.fetch))
      case .view(.backTapped):
        return .merge(.cancel(id: CancelID.fetch), .send(.delegate(.dismiss)))
      case .async(.fetch):
        guard let classID = state.classID else { return .none }
        state.isLoading = true
        state.errorMessage = nil
        return .run { [useCase = classBattleUseCase] send in
          let result = await Result { try await useCase.fetchMyPerspectives(classID: classID) }
            .mapError { ($0 as? ClassBattleError) ?? .network($0.localizedDescription) }
          await send(.inner(.perspectivesResponse(result)))
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
      case let .inner(.perspectivesResponse(result)):
        state.isLoading = false
        switch result {
        case let .success(items):
          state.opinions = items.map {
            ClassReportOpinion(
              id: String($0.id),
              kind: .unspecified,
              body: $0.content,
              stance: $0.option.stance ?? $0.option.title,
              likeCount: $0.likeCount,
              replyCount: $0.commentCount,
              authorName: $0.author.nickname
            )
          }
        case let .failure(error):
          state.errorMessage = error.message
        }
        return .none
      case .delegate:
        return .none
      }
    }
  }
}
