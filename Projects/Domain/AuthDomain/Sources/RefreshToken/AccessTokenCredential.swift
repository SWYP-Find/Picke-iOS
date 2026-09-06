//
//  AccessTokenCredential.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation
import LogMacro

struct AccessTokenCredential: Sendable {
  let accessToken: String
  let refreshToken: String
  let expiration: Date

  private let refreshLeadTime: TimeInterval = 5 * 60

  var requiresRefresh: Bool {
    Date().addingTimeInterval(refreshLeadTime) >= expiration
  }

  var isExpired: Bool {
    Date() >= expiration
  }

  static func make(
    accessToken: String,
    refreshToken: String
  ) -> AccessTokenCredential {
    let fallbackExpiration = Date().addingTimeInterval(24 * 60 * 60)
    let expiration: Date
    if let decodedExpiration = decodeExpiration(from: accessToken) {
      expiration = decodedExpiration
    } else {
      Log.debug("⚠️ JWT decoding failed, using fallback expiration: 24h from now")
      expiration = fallbackExpiration
    }

    return AccessTokenCredential(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiration: expiration
    )
  }
}

private extension AccessTokenCredential {
  static func decodeExpiration(from token: String) -> Date? {
    let components = token.components(separatedBy: ".")
    guard components.count == 3 else { return nil }

    let payload = components[1]
    var base64 = payload
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    let paddingLength = 4 - (base64.count % 4)
    if paddingLength < 4 {
      base64 += String(repeating: "=", count: paddingLength)
    }

    guard let data = Data(base64Encoded: base64),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let exp = json["exp"] as? TimeInterval
    else { return nil }

    return Date(timeIntervalSince1970: exp)
  }
}
