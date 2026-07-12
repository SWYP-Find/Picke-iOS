//
//  CommentOption.swift
//  Entity
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
