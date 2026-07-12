//
//  LoginFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import AuthenticationServices
import Foundation

import AuthInterface
import ComposableArchitecture
import LogMacro

import PickeDesignKit
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

    /// Apple/Google 신규 가입자 약관 동의 바텀시트. nil 이면 미표시.
    @Presents var termsAgreement: TermsAgreementFeature.State?

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
    case delegate(LoginDelegate)
    case termsAgreement(PresentationAction<TermsAgreementFeature.Action>)
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

  nonisolated enum CancelID: Hashable {
    case googleOAuth
    case appleOAuth
    case kakaoOAuth
  }

  @Dependency(\.appleManger) var appleLoginManger
  @Dependency(\.unifiedOAuthUseCase) var unifiedOAuthUseCase
  @Dependency(\.continuousClock) var clock
  @Dependency(\.analyticsUseCase) var analyticsUseCase

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

      case let .termsAgreement(presentationAction):
        handleTermsAgreement(state: &state, action: presentationAction)
      }
    }
    .ifLet(\.$termsAgreement, action: \.termsAgreement) {
      TermsAgreementFeature()
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
      return .send(.async(.login(socialType: social)))
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

        // 로그인 성공 직후 유저 고유 ID(userTag) 를 Mixpanel 에 연결.
        analyticsUseCase.identify(loginEntity.userTag, loginEntity.provider.rawValue)
        // 신규 가입(메인 진입) 시 sign_up.
        let provider = AnalyticsProvider(rawValue: loginEntity.provider.rawValue)
        if loginEntity.isNewUser {
          analyticsUseCase.track(.signUp(method: provider ?? .kakao))
        }
        // 온보딩 완료(홈 진입) 퍼널.
        analyticsUseCase.track(.onboardingStep(step: .homeEntered, provider: provider))

        guard loginEntity.isNewUser else {
          return .send(.delegate(.presentMainTab))
        }
        // 신규 가입자 중 Apple/Google 만 약관 동의 바텀시트 노출, 그 외(카카오)는 바로 온보딩.
        if state.currentSocialType == .apple || state.currentSocialType == .google {
          state.termsAgreement = TermsAgreementFeature.State()
          return .none
        }
        return .send(.delegate(.presentOnboarding))

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
    action: LoginDelegate
  ) -> Effect<Action> {
    switch action {
    case .presentOnboarding:
      return .none

    case .presentMainTab:
      return .none

    case .presentTermsWeb:
      // 코디네이터가 라우팅 처리. 리듀서에서는 부수효과 없음.
      return .none
    }
  }

  private func handleTermsAgreement(
    state: inout State,
    action: PresentationAction<TermsAgreementFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.confirmed)):
      // 약관 동의 완료 → 바텀시트 닫고 온보딩 진행.
      state.termsAgreement = nil
      return .send(.delegate(.presentOnboarding))

    case .presented(.delegate(.dismissed)), .dismiss:
      state.termsAgreement = nil
      return .none

    case let .presented(.delegate(.openDocument(document))):
      // 약관 상세 보기 → 코디네이터가 WebView 화면으로 라우팅.
      return .send(.delegate(.presentTermsWeb(urlString: document.urlString)))

    case .presented:
      return .none
    }
  }
}
