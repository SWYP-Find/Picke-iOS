//
//  AppleOAuthRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation
import AuthenticationServices

@preconcurrency import AuthDomainInterface

import ComposableArchitecture
import PickeCoreLogger

#if canImport(UIKit)
import UIKit
#endif

public final class AppleOAuthRepositoryImpl: NSObject, AppleOAuthInterface, @unchecked Sendable {
  @Dependency(\.appleManger) var appleLoginManger
  @Shared(.appleUserName) var appleUserName: String?

  private var currentNonce: String?
  private var signInContinuation: CheckedContinuation<AppleOAuthPayload, Error>?
  private var isSigningIn: Bool = false

  public override init() {

  }
  public func signInWithCredential(
    _ credential: ASAuthorizationAppleIDCredential,
    nonce: String
  ) async throws -> AppleOAuthPayload {
    // 받은 credential으로 직접 payload 생성
    guard let identityTokenData = credential.identityToken,
          let identityToken = String(data: identityTokenData, encoding: .utf8)
    else {
      throw AuthError.missingIDToken
    }

    let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
    let displayName = formatDisplayName(credential.fullName)

    return AppleOAuthPayload(
      idToken: identityToken,
      authorizationCode: authorizationCode,
      displayName: displayName,
      nonce: nonce
    )
  }

  @MainActor
  public func signIn() async throws -> AppleOAuthPayload {
    // 이미 진행 중인 로그인이 있으면 기다림
    if isSigningIn {
      return try await withCheckedThrowingContinuation { newContinuation in
        newContinuation.resume(throwing: AuthError.invalidCredential("이미 로그인이 진행 중입니다"))
      }
    }

    return try await withCheckedThrowingContinuation { continuation in
      self.isSigningIn = true
      self.signInContinuation = continuation

      let request = ASAuthorizationAppleIDProvider().createRequest()
      let nonce = appleLoginManger.prepare(request)
      self.currentNonce = nonce

      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      controller.performRequests()
    }
  }

  private func formatDisplayName(_ components: PersonNameComponents?) -> String? {
    guard let components else { return nil }
    let formatter = PersonNameComponentsFormatter()
    let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? nil : name
  }

  private func finishSignIn(with result: Result<AppleOAuthPayload, Error>) {
    let continuation = signInContinuation
    signInContinuation = nil
    currentNonce = nil
    isSigningIn = false
    continuation?.resume(with: result)
  }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleOAuthRepositoryImpl: ASAuthorizationControllerDelegate {
  public func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      finishSignIn(with: .failure(AuthError.invalidCredential("Invalid credential type")))
      return
    }

    guard let nonce = currentNonce else {
      finishSignIn(with: .failure(AuthError.missingIDToken))
      return
    }

    guard let identityTokenData = credential.identityToken,
          let identityToken = String(data: identityTokenData, encoding: .utf8) else {
      finishSignIn(with: .failure(AuthError.missingIDToken))
      return
    }

    let displayName = formatDisplayName(credential.fullName)
    let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }

    let payload = AppleOAuthPayload(
      idToken: identityToken,
      authorizationCode: authorizationCode,
      displayName: displayName,
      nonce: nonce
    )

    self.$appleUserName.withLock { $0 = displayName }

    PickeLogger.info("Apple Sign In 성공 — user: \(displayName ?? "unknown"), 저장된 이름: \(String(describing: appleUserName))", category: .auth)
    finishSignIn(with: .success(payload))
  }

  public func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    let nsError = error as NSError

    if nsError.code == ASAuthorizationError.canceled.rawValue {
      finishSignIn(with: .failure(AuthError.userCancelled))
    } else {
      PickeLogger.error("Apple Sign In 실패: \(error.localizedDescription)", category: .auth)
      finishSignIn(with: .failure(AuthError.invalidCredential(error.localizedDescription)))
    }
  }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleOAuthRepositoryImpl: ASAuthorizationControllerPresentationContextProviding {
  public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if canImport(UIKit)
    return UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first ?? ASPresentationAnchor()
#else
    return ASPresentationAnchor()
#endif
  }
}
