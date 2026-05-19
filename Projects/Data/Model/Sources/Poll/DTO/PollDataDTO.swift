//
//  PollDataDTO.swift
//  Model
//
//  `GET /api/v1/polls/{pollId}` 의 data 페이로드.
//

import Foundation

public struct PollDataDTO: Decodable {
  public let pollId: Int
  public let titlePrefix: String
  public let titleSuffix: String
  public let targetDate: String?
  public let status: String
  public let options: [PollOptionDTO]
}

public struct PollOptionDTO: Decodable, Identifiable {
  public let optionId: Int
  public let label: String
  public let title: String
  public let displayOrder: Int
  public let voteCount: Int

  public var id: Int { optionId }
}

public typealias PollResponseDTO = BaseResponseDTO<PollDataDTO>
