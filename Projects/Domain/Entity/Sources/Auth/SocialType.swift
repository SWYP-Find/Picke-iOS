//
//  SocialType.swift
//  Entity
//
//  Created by Wonji Suh  on 5/14/26.
//

public enum SocialType: String, CaseIterable, Identifiable, Hashable {
  case none
  case kakao
  case apple
  case google
  
  
  public var id: String { rawValue }
  
  var description: String {
    switch self {
    case .none:
      return "email"
    case .kakao:
      return "kakao"
    case .apple:
      return "Apple"
    case .google:
      return "Google"
      
    }
  }
  
  
  public var image: String {
    switch self {
    case .kakao:
      return "kakao"
    case .apple:
      return "apple.logo"
    case .google:
      return "google"
    case .none:
      return ""
    }
  }
}
