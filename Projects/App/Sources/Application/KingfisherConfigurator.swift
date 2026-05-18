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

import DomainInterface
import Foundations

enum KingfisherConfigurator {
  static func configureAuthorizedDownloader(
    keychainManager: KeychainManaging
  ) {
    let modifier = AnyModifier { request in
      var req = request
      if let token = keychainManager.accessToken(), !token.isEmpty {
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      }
      return req
    }

    KingfisherManager.shared.defaultOptions = [
      .requestModifier(modifier),
    ]
  }
}
