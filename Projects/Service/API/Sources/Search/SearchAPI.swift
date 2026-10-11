//
//  SearchAPI.swift
//  API
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum SearchAPI {
  case battles

  public var description: String {
    switch self {
    case .battles:
      return "battles"
    }
  }
}
