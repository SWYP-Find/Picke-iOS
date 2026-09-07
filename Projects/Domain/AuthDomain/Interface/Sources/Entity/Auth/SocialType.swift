//
//  SocialType.swift
//  Entity
//
//  Created by Wonji Suh  on 5/14/26.
//

public enum SocialType: String, CaseIterable, Identifiable, Hashable {
  case kakao
  case apple
  case google

  public var id: String { rawValue }

  var description: String {
    switch self {
    case .kakao:
      "kakao"
    case .apple:
      "Apple"
    case .google:
      "Google"
    }
  }

  public var image: String {
    switch self {
    case .kakao:
      "kakao"
    case .apple:
      "apple.logo"
    case .google:
      "google"
    }
  }

  /// 백엔드 OAuth code 교환에 사용되는 redirect URI.
  /// 카카오/구글 authorize URL 에 그대로 사용한 값과 동일해야 한다.
  public var redirectUri: String {
    switch self {
    case .kakao:
      "https://picke.store/oauth/kakao"
    case .google:
      "https://picke.store/oauth/google"
    case .apple:
      ""
    }
  }
}
