//
//  UserSessionSharedKey.swift
//  AuthDomainInterface
//

import Foundation

import PickeStorageInterface

import Sharing

public extension SharedReaderKey where Self == PersistentSharedKey<UserSession>.Default {
  /// 앱 실행 사이에 유지되는 사용자 세션 메타데이터.
  static var userSession: Self {
    Self[
      .persistent(
        "UserSession",
        encode: { session in
          try JSONEncoder().encode(UserSessionSnapshot(session))
        },
        decode: { data in
          try JSONDecoder().decode(UserSessionSnapshot.self, from: data).userSession
        }
      ),
      default: .empty
    ]
  }
}

private struct UserSessionSnapshot: Codable, Sendable {
  let schemaVersion: Int
  let name: String
  let provider: String

  init(_ session: UserSession) {
    schemaVersion = 1
    name = session.name
    provider = session.provider.rawValue
  }

  var userSession: UserSession {
    UserSession(
      name: name,
      provider: SocialType(rawValue: provider) ?? .apple
    )
  }
}
