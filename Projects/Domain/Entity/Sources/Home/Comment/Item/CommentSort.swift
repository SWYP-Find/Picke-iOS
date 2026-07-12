//
//  CommentSort.swift
//  Entity
//

import CommonDomainInterface
import Foundation

public enum CommentSort: String, CaseIterable, Equatable {
  case popular
  case latest

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }

  public var perspectiveSort: BattlePerspectiveSort {
    switch self {
    case .popular: .popular
    case .latest: .latest
    }
  }
}
