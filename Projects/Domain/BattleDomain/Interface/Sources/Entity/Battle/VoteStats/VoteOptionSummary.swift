//
//  VoteOptionSummary.swift
//  BattleDomainInterface
//
//  Created by Picke on 10/11/26.
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

public extension VoteOptionSummary {
  /// Android `formatRate` — 소수 한 자리, `.0`이면 뗀다("59%", "59.5%").
  var rateLabel: String {
    let text = String(format: "%.1f", percentage * 100)
    return (text.hasSuffix(".0") ? String(text.dropLast(2)) : text) + "%"
  }
}
