//
//  CommentOption.swift
//  CommentDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum CommentOption: Equatable {
  case a
  case b

  public var label: String {
    switch self {
    case .a: "A"
    case .b: "B"
    }
  }
}
