//
//  VoteOptionSummary.swift
//  Entity
//

import Foundation

public struct VoteOptionSummary: Equatable {
  public var optionId: Int
  public var label: String
  public var title: String
  public var representative: String
  public var imageUrl: String?
  public var percentage: Double

  public init(
    optionId: Int = 0,
    label: String,
    title: String,
    representative: String,
    imageUrl: String? = nil,
    percentage: Double
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.representative = representative
    self.imageUrl = imageUrl
    self.percentage = percentage
  }
}
