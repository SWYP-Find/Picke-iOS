//
//  KeychainCredentialStoreTests.swift
//  PickeAuthTests
//

import Foundation
import Testing

@testable import PickeAuth
import PickeNetworkInterface
import PickeStorageInterface

struct KeychainCredentialStoreTests {
  @Test
  func 토큰쌍이_모두_있으면_credential_을_복원한다() throws {
    let storage = FakeSecureStorage(values: [
      .accessToken: "access",
      .refreshToken: "refresh"
    ])

    let credential = try #require(KeychainCredentialStore(storage: storage).load())

    #expect(credential.accessToken == "access")
    #expect(credential.refreshToken == "refresh")
  }

  @Test
  func 토큰이_하나라도_비면_credential_을_복원하지_않는다() {
    let storage = FakeSecureStorage(values: [.accessToken: "access"])

    #expect(KeychainCredentialStore(storage: storage).load() == nil)
  }

  @Test
  func credential_을_저장하면_토큰쌍이_보관된다() {
    let storage = FakeSecureStorage()
    let sut = KeychainCredentialStore(storage: storage)

    sut.save(PickeCredential(accessToken: "new-access", refreshToken: "new-refresh"))

    #expect(storage.values[.accessToken] == "new-access")
    #expect(storage.values[.refreshToken] == "new-refresh")
  }

  @Test
  func clear_는_보관된_토큰을_모두_지운다() {
    let storage = FakeSecureStorage(values: [
      .accessToken: "access",
      .refreshToken: "refresh"
    ])

    KeychainCredentialStore(storage: storage).clear()

    #expect(storage.values.isEmpty)
  }
}
