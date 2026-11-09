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
    /// 레거시 리포트 경로(서버 결과가 없을 때) 코디네이터가 채우는 스냅샷.
    public var opinions: [ClassReportOpinion] = []
    /// 서버 경로: 클래스에서 내가 쓴 공개 의견(Android `남긴 댓글`).
    public var perspectiveOpinions: [ClassReportOpinion] = []
    /// 서버 경로: 내 활동 API의 내가 남긴 댓글(Android `남긴 대댓글`).
    public var replyOpinions: [ClassReportOpinion] = []
    public var classID: Int?
    public var isLoading = false
    public var errorMessage: String?
    public var myDisplayName: String?
    public var nextCursor: String?
    public var hasNext = false
    public var isLoadingMore = false
    public var toastMessage: String?

    public var comments: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .comment }
    }

    public var replies: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .reply }
    }

    public var unspecified: [ClassMyOpinionRow] {
      rows.filter { $0.opinion.kind == .unspecified }
    }

    public var isEmpty: Bool {
      opinions.isEmpty && perspectiveOpinions.isEmpty && replyOpinions.isEmpty
    }

    public var canLoadMoreReplies: Bool {
      hasNext && nextCursor != nil && !isLoadingMore
    }

    private var rows: [ClassMyOpinionRow] {
      (opinions + perspectiveOpinions + replyOpinions)
        .enumerated()
        .map { ClassMyOpinionRow(index: $0.offset, opinion: $0.element) }
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
    case repliesEndReached
    case toastShown
  }

  @CasePathable
  public enum AsyncAction: Equatable {
    case fetch
    case fetchReplies
    case fetchReplyPage(cursor: String?)
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case perspectivesResponse(Result<[ClassPerspectiveItem], ClassBattleError>)
    case myDisplayNameResponse(Result<String, ClassError>)
    case replyPageResponse(cursor: String?, Result<ClassMyActivity, ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public enum CancelID: Hashable, Sendable {
    case fetch
    case replies
    case moreReplies
  }

  static let loadFailedMessage = "정보를 불러오지 못했어요"

  @Dependency(\.classBattleUseCase) private var classUseCase
  @Dependency(\.classMemberUseCase) private var memberUseCase
  @Dependency(\.classResultUseCase) private var resultUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case .delegate:
        return .none
      }
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.classID != nil,
            !state.isLoading,
            state.perspectiveOpinions.isEmpty,
            state.replyOpinions.isEmpty,
            state.errorMessage == nil else { return .none }
      return .merge(.send(.async(.fetch)), .send(.async(.fetchReplies)))
    case .retryTapped:
      guard state.classID != nil, !state.isLoading else { return .none }
      state.perspectiveOpinions = []
      state.replyOpinions = []
      state.nextCursor = nil
      state.hasNext = false
      state.isLoadingMore = false
      return .concatenate(
        .cancel(id: CancelID.replies),
        .cancel(id: CancelID.moreReplies),
        .merge(.send(.async(.fetch)), .send(.async(.fetchReplies)))
      )
    case .backTapped:
      return .merge(
        .cancel(id: CancelID.fetch),
        .cancel(id: CancelID.replies),
        .cancel(id: CancelID.moreReplies),
        .send(.delegate(.dismiss))
      )
    case .repliesEndReached:
      guard state.canLoadMoreReplies else { return .none }
      return .send(.async(.fetchReplyPage(cursor: state.nextCursor)))
    case .toastShown:
      state.toastMessage = nil
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetch:
      guard let classID = state.classID else { return .none }
      state.isLoading = true
      state.errorMessage = nil
      return .run { [useCase = classUseCase] send in
        let result = await Result { try await useCase.fetchMyPerspectives(classID: classID) }
          .mapError { ($0 as? ClassBattleError) ?? .network($0.localizedDescription) }
        await send(.inner(.perspectivesResponse(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    case .fetchReplies:
      guard let classID = state.classID else { return .none }
      return .run { [memberUseCase] send in
        let result = await Result {
          let list = try await memberUseCase.fetchMembers(classID: classID)
          return list.members.first { $0.id == list.currentMemberID }?.name ?? ""
        }
        .mapError(ClassError.from)
        await send(.inner(.myDisplayNameResponse(result)))
      }
      .cancellable(id: CancelID.replies, cancelInFlight: true)
    case let .fetchReplyPage(cursor):
      guard let classID = state.classID else { return .none }
      if cursor != nil { state.isLoadingMore = true }
      return .run { [resultUseCase] send in
        let result = await Result {
          try await resultUseCase.fetchMyActivity(roomID: classID, cursor: cursor)
        }
        .mapError(ClassError.from)
        await send(.inner(.replyPageResponse(cursor: cursor, result)))
      }
      .cancellable(id: cursor == nil ? CancelID.replies : CancelID.moreReplies, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .perspectivesResponse(result):
      state.isLoading = false
      switch result {
      case let .success(items):
        // Android `PerspectiveStatus.from`처럼 알 수 없는 상태는 공개로 보고 검수 중·거절만 뺀다.
        state.perspectiveOpinions = items
          .filter { !["PENDING", "REJECTED"].contains($0.status?.uppercased() ?? "") }
          .map {
            ClassReportOpinion(
              id: String($0.id),
              kind: .comment,
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
    case let .myDisplayNameResponse(result):
      switch result {
      case let .success(name):
        state.myDisplayName = name
        return .send(.async(.fetchReplyPage(cursor: nil)))
      case .failure:
        state.toastMessage = Self.loadFailedMessage
        return .none
      }
    case let .replyPageResponse(cursor, result):
      state.isLoadingMore = false
      switch result {
      case let .success(activity):
        let name = state.myDisplayName.flatMap { $0.isEmpty ? nil : $0 } ?? "나"
        let page = activity.comments.map { comment in
          ClassReportOpinion(
            id: "reply-\(comment.id)",
            kind: .reply,
            body: comment.content,
            likeCount: comment.likeCount,
            authorName: name,
            parent: ClassReportReplyContext(authorName: nil, stance: nil, body: comment.perspectiveTitle)
          )
        }
        // 첫 페이지는 교체하고 다음 페이지만 이어 붙여 다시 나타날 때 중복되지 않게 한다.
        state.replyOpinions = cursor == nil ? page : state.replyOpinions + page
        state.nextCursor = activity.nextCursor
        state.hasNext = activity.hasNext
      case .failure:
        state.toastMessage = Self.loadFailedMessage
        // Android `RequestFailed`처럼 다음 페이지 실패 시 더 불러오기를 멈춰 무한 로딩·반복 토스트를 막는다.
        if cursor != nil { state.hasNext = false }
      }
      return .none
    }
  }
}
