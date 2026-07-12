//
//  APIHeader.swift
//  NetworkHeader
//
//  Created by Wonji Suh  on 5/7/25.
//

import Foundation
import NetworkToken
import WeaveDI

public struct APIHeader {
  public static let contentType = "Content-Type"
  public static let accessToken = "Authorization"
  public static let refreshToken = "X-Refresh-Token"
  public static let accept = "accept"

  @Dependency(\.tokenProvider) private static var tokenProvider

  public static var accessTokenKeyChain: String {
    get {
      let token = tokenProvider.accessToken() ?? ""
      return token
    }
    set { updateAccessToken(newValue) }
  }

  public static func updateAccessToken(_ token: String?) {
    guard let newToken = token, !newToken.isEmpty else {
      tokenProvider.clearAccessToken()
      return
    }
    tokenProvider.saveAccessToken(newToken)
  }

  public init() {}
}

public extension APIHeader {
  internal static func baseHeaders(_ headers: [String: String]?) -> [String: String] {
    var baseHeaders = baseHeader
    if let headers {
      baseHeaders.merge(headers) { $1 }
    }
    return baseHeaders
  }

  static var baseHeader: [String: String] {
    [
      contentType: APIHeaderManger.contentType,
      accessToken: "Bearer \(accessTokenKeyChain)",
      accept: APIHeaderManger.contentType,
    ]
  }

  static var notAccessTokenHeader: [String: String] {
    [
      contentType: APIHeaderManger.contentType,
      accept: APIHeaderManger.contentType,
    ]
  }

  static var mutiPartbaseHeader: [String: String] {
    [
      contentType: APIHeaderManger.multipartContentType,
      accessToken: "Bearer \(accessTokenKeyChain)",
    ]
  }

  static var applebaseHeader: [String: String] {
    [
      contentType: APIHeaderManger.contentType,
      accept: APIHeaderManger.contentType,
    ]
  }
}
