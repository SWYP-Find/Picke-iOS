//
//  AdsImpressionsRequest.swift
//  APIEndpoint
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct AdsImpressionsRequest: Encodable, Sendable {
  public let codes: [String]

  public init(codes: [String]) {
    self.codes = codes
  }
}
