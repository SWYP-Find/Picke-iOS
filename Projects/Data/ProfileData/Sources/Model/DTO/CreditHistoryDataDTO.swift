//
//  CreditHistoryDataDTO.swift
//  Model
//

import Foundation
import Model

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

public typealias CreditHistoryResponseDTO = BaseResponseDTO<CreditHistoryDataDTO>
