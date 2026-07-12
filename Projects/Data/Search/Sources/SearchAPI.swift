//
//  SearchAPI.swift
//  API
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
