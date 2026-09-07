//
//  AuthRepositoryTests.swift
//  AuthDataTests
//

import Foundation

import Dependencies
import Testing

@testable import AuthData

import APIEndpoint
import AuthDomainInterface

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
  func login_emptyData_throwsBackendError() async throws {
    let fixture = Data("""
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "AUTH_400", "message": "로그인에 실패했습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    do {
      _ = try await repo.login(
        provider: .kakao,
        authorizationCode: "code-kakao",
        redirectUri: nil,
        idToken: nil
      )
      Issue.record("로그인 실패 응답인데 에러가 던져지지 않았습니다")
    } catch let error as AuthError {
      #expect(error == .backendError("로그인에 실패했습니다"))
    } catch {
      Issue.record("예상치 못한 에러 타입: \(error)")
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
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    let tokens = try await repo.refresh()

    #expect(tokens.accessToken == "access-2")
    #expect(tokens.refreshToken == "refresh-2")
  }

  @Test
  func refresh_emptyData_throwsBackendError() async throws {
    let fixture = Data("""
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "AUTH_401", "message": "토큰 재발급에 실패했습니다" }
    }
    """.utf8)

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: fixture)
    } operation: {
      AuthRepositoryImpl()
    }

    do {
      _ = try await repo.refresh()
      Issue.record("토큰 재발급 실패 응답인데 에러가 던져지지 않았습니다")
    } catch let error as AuthError {
      #expect(error == .backendError("토큰 재발급에 실패했습니다"))
    } catch {
      Issue.record("예상치 못한 에러 타입: \(error)")
    }
  }

  @Test
  func refresh_providerThrows_rethrowsOriginalError() async throws {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      AuthRepositoryImpl()
    }

    do {
      _ = try await repo.refresh()
      Issue.record("provider 가 에러를 던졌는데 refresh() 가 에러를 던지지 않았습니다")
    } catch is ThrowingStubNetworkClient.StubError {
      // AFError 도, "statusCodeError(401)" 문자열도 아니므로 원본 에러가 그대로 다시 던져져야 한다.
    } catch {
      Issue.record("예상치 못한 에러 타입: \(error)")
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
  func updateSessionCredential_doesNotCrash() {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      AuthRepositoryImpl()
    }

    repo.updateSessionCredential(with: AuthTokens(accessToken: "a", refreshToken: "r"))
  }
}
