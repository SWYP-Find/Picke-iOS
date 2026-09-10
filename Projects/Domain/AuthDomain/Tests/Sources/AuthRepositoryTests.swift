//
//  AuthRepositoryTests.swift
//  AuthDataTests
//

import Foundation

import Dependencies
import Testing

@testable import AuthDomain

import APIEndpoint
import AuthDomainInterface
import PickeAuthInterface

struct AuthRepositoryTests {
  // MARK: - login

  @Test
  func login_success_mapsToLoginEntity() async throws {
    let fixture = Data("""
    {
      "statusCode": 200,
      "data": {
        "access_token": "access-1",
        "refresh_token": "refresh-1",
        "user_tag": "user#1234",
        "status": "active",
        "new_user": true
      },
      "error": null
    }
    """.utf8)

    let repo = withDependencies {
      $0.authService = RecordingAuthService(refreshToken: "refresh-1")
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.login(
      provider: .kakao,
      authorizationCode: "code-kakao",
      redirectUri: "https://picke.store/oauth/kakao",
      idToken: nil
    )

    #expect(entity.provider == .kakao)
    #expect(entity.isNewUser == true)
    #expect(entity.userTag == "user#1234")
    #expect(entity.status == "active")
    #expect(entity.token.accessToken == "access-1")
    #expect(entity.token.refreshToken == "refresh-1")
  }

  @Test
  func login_errorEnvelope_throwsNetworkResponseError() async throws {
    let fixture = Data("""
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "AUTH_400", "message": "로그인에 실패했습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.authService = RecordingAuthService(refreshToken: "refresh-1")
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 400,
      code: "AUTH_400",
      message: "로그인에 실패했습니다"
    ) {
      _ = try await repo.login(
        provider: .kakao,
        authorizationCode: "code-kakao",
        redirectUri: nil,
        idToken: nil
      )
    }
  }

  // MARK: - refresh

  @Test
  func refresh_success_mapsToAuthTokens() async throws {
    let fixture = Data("""
    {
      "statusCode": 200,
      "data": {
        "access_token": "access-2",
        "refresh_token": "refresh-2"
      },
      "error": null
    }
    """.utf8)

    let repo = withDependencies {
      $0.authService = RecordingAuthService(refreshToken: "refresh-1")
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    let tokens = try await repo.refresh()

    #expect(tokens.accessToken == "access-2")
    #expect(tokens.refreshToken == "refresh-2")
  }

  @Test
  func refresh_errorEnvelope_throwsNetworkResponseError() async throws {
    let fixture = Data("""
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "AUTH_401", "message": "토큰 재발급에 실패했습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.authService = RecordingAuthService(refreshToken: "refresh-1")
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 400,
      code: "AUTH_401",
      message: "토큰 재발급에 실패했습니다"
    ) {
      _ = try await repo.refresh()
    }
  }

  @Test
  func refresh_providerThrows_rethrowsOriginalError() async throws {
    let repo = withDependencies {
      $0.authService = RecordingAuthService(refreshToken: "refresh-1")
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      AuthRepositoryImpl()
    }

    await expectNetworkTransportError(
      underlyingError: ThrowingStubNetworkClient.StubError.self
    ) {
      _ = try await repo.refresh()
    }
  }

  // MARK: - logout

  @Test
  func logout_success_mapsToAuthExitEntity() async throws {
    let fixture = Data("""
    {
      "statusCode": 200,
      "data": { "logged_out": true },
      "error": null
    }
    """.utf8)

    let repo = withDependencies {
      $0.authService = RecordingAuthService()
      $0.networkClient = StubNetworkClient(stubData: fixture, statusCode: 200)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.logout()

    #expect(entity.loggedOut == true)
    #expect(entity.code == nil)
    #expect(entity.message == nil)
  }

  @Test
  func logout_emptyBody_defaultsToLoggedOutTrue() async throws {
    let repo = withDependencies {
      $0.authService = RecordingAuthService()
      $0.networkClient = StubNetworkClient(stubData: Data(), statusCode: 200)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.logout()

    #expect(entity.loggedOut == true)
  }

  @Test
  func logout_errorStatus_mapsErrorCodeAndMessage() async throws {
    let fixture = Data("""
    {
      "statusCode": 500,
      "data": null,
      "error": { "code": "AUTH_500", "message": "로그아웃에 실패했습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: fixture, statusCode: 500)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.logout()

    #expect(entity.loggedOut == false)
    #expect(entity.code == "AUTH_500")
    #expect(entity.message == "로그아웃에 실패했습니다")
  }

  // MARK: - withDraw

  @Test
  func withDraw_success_mapsToWithdrawEntity() async throws {
    let fixture = Data("""
    {
      "statusCode": 200,
      "data": { "withdrawn": true },
      "error": null
    }
    """.utf8)

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: fixture, statusCode: 200)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.withDraw(reason: "NOT_USED_OFTEN")

    #expect(entity.isSuccess == true)
    #expect(entity.withdrawn == true)
    #expect(entity.code == nil)
  }

  @Test
  func withDraw_emptyBody_defaultsToSuccessTrue() async throws {
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(), statusCode: 200)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.withDraw(reason: "NOT_USED_OFTEN")

    #expect(entity.isSuccess == true)
    #expect(entity.withdrawn == true)
  }

  @Test
  func withDraw_errorStatus_mapsErrorCodeAndMessage() async throws {
    let fixture = Data("""
    {
      "statusCode": 403,
      "data": null,
      "error": { "code": "AUTH_403", "message": "탈퇴 권한이 없습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: fixture, statusCode: 403)
    } operation: {
      AuthRepositoryImpl()
    }

    let entity = try await repo.withDraw(reason: "NOT_USED_OFTEN")

    #expect(entity.isSuccess == false)
    #expect(entity.code == "AUTH_403")
    #expect(entity.message == "탈퇴 권한이 없습니다")
  }

  // MARK: - updateSessionCredential

  @Test
  func updateSessionCredential_passesTokensToAuthService() async {
    let authService = RecordingAuthService()
    let repo = withDependencies {
      $0.authService = authService
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      AuthRepositoryImpl()
    }

    await repo.updateSessionCredential(
      with: AuthTokens(accessToken: "access-token", refreshToken: "refresh-token")
    )

    let tokens = await authService.recordedTokens()
    #expect(tokens?.accessToken == "access-token")
    #expect(tokens?.refreshToken == "refresh-token")
  }
}

private actor RecordingAuthService: PickeAuthInterface.AuthService {
  private var accessToken: String?
  private var storedRefreshToken: String?

  init(refreshToken: String? = nil) {
    storedRefreshToken = refreshToken
  }

  var isLoggedIn: Bool {
    get async { accessToken != nil && storedRefreshToken != nil }
  }

  var refreshToken: String? {
    get async { storedRefreshToken }
  }

  func signIn(
    accessToken: String,
    refreshToken: String
  ) async {
    self.accessToken = accessToken
    storedRefreshToken = refreshToken
  }

  func signOut() async {
    accessToken = nil
    storedRefreshToken = nil
  }

  func recordedTokens() -> AuthTokens? {
    guard let accessToken, let storedRefreshToken else { return nil }
    return AuthTokens(accessToken: accessToken, refreshToken: storedRefreshToken)
  }
}
