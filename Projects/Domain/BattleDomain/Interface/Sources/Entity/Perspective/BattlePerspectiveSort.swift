//
//  BattlePerspectiveSort.swift
//  BattleDomainInterface
//

import Foundation

public enum BattlePerspectiveSort: String, Equatable, Hashable, CaseIterable {
  case popular
  case latest

  public var queryValue: String { rawValue }

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }
}
