//
//  HomeService.swift
//  Service
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import Alamofire
import API
import PickeNetwork

public enum HomeService {
  case home
}

extension HomeService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.home }

  public var path: String {
    switch self {
    case .home:
      return HomeAPI.home.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .home:
      return .get
    }
  }
}
