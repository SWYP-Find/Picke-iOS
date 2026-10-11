//
//  AdsAPI.swift
//  API
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum AdsAPI: String, CaseIterable {
  case ads
  case impressions

  public var description: String {
    switch self {
    case .ads:
      return ""
    case .impressions:
      return "/impressions"
    }
  }
}
