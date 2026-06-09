//
//  RecapCard.swift
//  Entity
//
//  철학자 카드 (내 카드 / 궁합 best·worst).
//

import Foundation

public struct RecapCard: Equatable {
  public let philosopherType: String
  public let philosopherLabel: String
  /// 유형명 (예: `칸트형`).
  public let typeName: String
  public let description: String
  public let keywordTags: [String]
  public let imageURL: String

  public init(
    philosopherType: String,
    philosopherLabel: String,
    typeName: String,
    description: String,
    keywordTags: [String],
    imageURL: String
  ) {
    self.philosopherType = philosopherType
    self.philosopherLabel = philosopherLabel
    self.typeName = typeName
    self.description = description
    self.keywordTags = keywordTags
    self.imageURL = imageURL
  }
}
