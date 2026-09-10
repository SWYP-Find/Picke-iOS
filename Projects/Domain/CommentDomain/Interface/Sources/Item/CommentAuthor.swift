//
//  CommentAuthor.swift
//  Entity
//

import Foundation

public struct CommentAuthor: Equatable, Hashable {
  public let name: String
  public let imageURL: String?
  public let optionLabel: String?

  public init(
    name: String,
    imageURL: String? = nil,
    optionLabel: String? = nil
  ) {
    self.name = name
    self.imageURL = imageURL
    self.optionLabel = optionLabel
  }
}
