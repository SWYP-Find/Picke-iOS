//
//  LoginFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import AuthenticationServices
import Foundation

import ComposableArchitecture
import LogMacro

import DesignSystem
import Entity
import UseCase

@Reducer
public struct LoginFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var currentSocialType: SocialType?
    var nonce: String = ""
    var appleAccessToken: String = ""
    var appleLoginFullName: ASAuthorizationAppleIDCredential?
    @Shared var userSession: UserSession
    var loginEntity: LoginEntity?

    public init(
      userSession: UserSession = .empty
    ) {
      _userSession = Shared(wrappedValue: userSession, .inMemory("UserSession"))
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  // MARK: - ViewAction

  @CasePathable
  public enum View {
    case signInWithSocial(social: SocialType)
  }

  // MARK: - AsyncAction 비동기 처리 액션

  public enum AsyncAction {
    case prepareAppleRequest(ASAuthorizationAppleIDRequest)
    case appleLogin(Result<ASAuthorization, Error>, nonce: String)
    case login(socialType: SocialType)
  }

  // MARK: - 앱내에서 사용하는 액션

  public enum InnerAction: Equatable {
    case loginResponse(Result<LoginEntity, AuthError>)
  }

  // MARK: - NavigationAction

  public enum DelegateAction: Equatable {}

  nonisolated enum CancelID: Hashable {
    case googleOAuth
    case appleOAuth
    case kakaoOAuth
  }

  @Dependency(\.appleManger) var appleLoginManger
  @Dependency(\.unifiedOAuthUseCase) var unifiedOAuthUseCase
  @Dependency(\.continuousClock) var clock

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        .none

      case let .view(viewAction):
        handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        handleInnerAction(state: &state, action: innerAction)

      case let .delegate(delegateAction):
        handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension LoginFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case let .signInWithSocial(social):
      .send(.async(.login(socialType: social)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .prepareAppleRequest(request):
      let nonce = appleLoginManger.prepare(request)
      state.nonce = nonce
      return .none

    case let .appleLogin(result, nonce):
      state.currentSocialType = .apple
      return .run { send in
        guard
          case let .success(auth) = result,
          let credential = auth.credential as? ASAuthorizationAppleIDCredential,
          !nonce.isEmpty
        else {
          await send(.inner(.loginResponse(.failure(.invalidCredential("Apple 인증 정보가 없습니다")))))
          return
        }

        // Apple credential을 직접 처리하여 로그인 완료
        let outcome = await unifiedOAuthUseCase.processOAuthFlow(
          with: .apple,
          appleCredential: credential,
          nonce: nonce,
          googleToken: nil
        )
        await send(.inner(.loginResponse(outcome)))
      }
      .cancellable(id: CancelID.appleOAuth)

    case let .login(socialType):
      state.currentSocialType = socialType
      state.$userSession.withLock { $0.provider = socialType }
      return .run { [
        appleCredential = state.appleLoginFullName,
        nonce = state.nonce
      ] send in
        // Google/Kakao Provider 는 실제 토큰 대신 트리거 문자열만 받음 (내부에서 OAuth 플로우를 시작).
        let outcome = await unifiedOAuthUseCase.processOAuthFlow(
          with: socialType,
          appleCredential: appleCredential,
          nonce: nonce,
          googleToken: socialType == .google ? "google" : nil,
          kakaoToken: socialType == .kakao ? "kakao" : nil
        )
        return await send(.inner(.loginResponse(outcome)))
      }
      .cancellable(id: {
        switch socialType {
        case .apple: CancelID.appleOAuth
        case .google: CancelID.googleOAuth
        case .kakao: CancelID.kakaoOAuth
        }
      }())
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .loginResponse(result):
      switch result {
      case let .success(loginEntity):
        state.loginEntity = loginEntity
        return .none

//        if loginEntity.isNewUser  {
//          return .send(.view(.showPolicyPopUp))
//        } else if state.userSession.userRole == .manager {
//          return .send(.navigation(.presentStaffMain))
//        } else  {
//          return .send(.navigation(.presentMemberMain))
//        }

      case let .failure(error):
        #logNetwork("로그인 실패", error.localizedDescription)
        let socialType = state.currentSocialType
        return .run { _ in
          await MainActor.run {
            let errorMessage = switch socialType {
            case .apple:
              "Apple 인증에 실패하였습니다."
            case .google:
              "구글 인증에 실패하였습니다."
            case .kakao:
              "카카오 인증에 실패하였습니다."
            default:
              "인증에 실패했어요. 다시 시도해주세요."
            }
            ToastManager.shared.showError(errorMessage)
          }
        }
      }
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {}
  }
}
