//
//  CommentSortType.swift
//  CommentDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum CommentSortType: String, Equatable, Hashable, CaseIterable {
  case popular = "POPULAR"
  case latest = "LATEST"

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }
}
