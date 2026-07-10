//
//  KingfisherConfigurator.swift
//  App
//
//  Picke 백엔드 보호 이미지(`/api/v1/resources/...`) 를 KFImage 로 로딩하려면
//  요청마다 Bearer 토큰이 필요하다. 앱 시작 시 한 번만 호출해서
//  KingfisherManager 의 defaultOptions 에 글로벌 requestModifier 를 등록한다.
//

import Foundation

import Kingfisher

import Domain

enum KingfisherConfigurator {
  /// 보호 이미지 (picke 백엔드 `/api/v1/resources/...`) 에만 Bearer 토큰을 첨부한다.
  /// 그 외 외부 호스트 (picsum.photos / 카카오 CDN 등) 로는 토큰을 절대 보내지 않는다.
  private static let protectedHostSuffixes: Set<String> = [
    "picke.store",
    "dev.picke.store",
  ]

  static func configureAuthorizedDownloader(
    keychainManager: KeychainManaging
  ) {
    let modifier = AnyModifier { request in
      var req = request

      guard
        let url = req.url,
        let host = url.host?.lowercased(),
        protectedHostSuffixes.contains(where: { host == $0 || host.hasSuffix(".\($0)") }),
        url.path.hasPrefix("/api/"),
        let token = keychainManager.accessToken(), !token.isEmpty
      else {
        return req
      }

      req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      return req
    }

    KingfisherManager.shared.defaultOptions = [
      .requestModifier(modifier),
    ]
  }
}
