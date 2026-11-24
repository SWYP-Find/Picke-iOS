//
//  CredentialUpdating.swift
//  PickeNetworkInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

/// 인증 세션의 credential 을 외부에서 교체하는 핸들.
public protocol CredentialUpdating: Sendable {
  func update(_ credential: PickeCredential?)
}
