//
//  APIHeader.swift
//  PickeNetworkInterface
//
//  Created by Wonji Suh  on 5/7/25.
//

import Foundation

/// 요청 헤더 키 상수.
///
/// 공통 헤더(Accept 등)는 세션이, `Authorization` 은 `PickeAuthenticator` 가 붙인다.
/// 여기엔 엔드포인트가 직접 헤더를 조립할 때 쓰는 키 이름만 둔다.
public enum APIHeader {
  public static let contentType = "Content-Type"
  public static let accessToken = "Authorization"
  public static let refreshToken = "X-Refresh-Token"
  public static let accept = "accept"
}
