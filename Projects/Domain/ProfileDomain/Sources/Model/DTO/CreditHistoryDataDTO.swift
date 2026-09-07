//
//  CreditHistoryDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct CreditHistoryDataDTO: Decodable {
  public let items: [CreditHistoryItemDTO]?
  public let nextOffset: Int?
  public let hasNext: Bool?
}

public struct CreditHistoryItemDTO: Decodable {
  public let id: Int?
  public let creditType: String?
  public let amount: Int?
  public let referenceId: Int?
  public let createdAt: String?
}
