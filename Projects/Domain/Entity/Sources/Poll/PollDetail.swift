//
//  PollDetail.swift
//  Entity
//
//  `GET /api/v1/polls/{pollId}` 응답에서 사용하는 도메인 모델.
//

import Foundation

public struct PollDetail: Equatable, Identifiable {
  public let pollId: Int
  public let titlePrefix: String
  public let titleSuffix: String
  public let targetDate: Date?
  public let status: PollStatus
  public let options: [PollOption]

  public var id: Int { pollId }

  public init(
    pollId: Int,
    titlePrefix: String,
    titleSuffix: String,
    targetDate: Date?,
    status: PollStatus,
    options: [PollOption]
  ) {
    self.pollId = pollId
    self.titlePrefix = titlePrefix
    self.titleSuffix = titleSuffix
    self.targetDate = targetDate
    self.status = status
    self.options = options
  }
}

public struct PollOption: Equatable, Identifiable, Hashable {
  public let optionId: Int
  public let label: String
  public let title: String
  public let displayOrder: Int
  public let voteCount: Int

  public var id: Int { optionId }

  public init(
    optionId: Int,
    label: String,
    title: String,
    displayOrder: Int,
    voteCount: Int
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.displayOrder = displayOrder
    self.voteCount = voteCount
  }
}

public enum PollStatus: String, Equatable, Hashable, CaseIterable {
  case pending = "PENDING"
  case active = "ACTIVE"
  case closed = "CLOSED"
  case unknown

  public init(rawValue: String) {
    self = PollStatus.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}

public extension PollDetail {
  /// 전체 참여 수 = options.voteCount 의 합
  var totalVoteCount: Int { options.reduce(0) { $0 + $1.voteCount } }

  /// 옵션별 비율 (0~100). totalVoteCount 가 0 이면 모두 0.
  func percentage(for option: PollOption) -> Int {
    guard totalVoteCount > 0 else { return 0 }
    return Int((Double(option.voteCount) / Double(totalVoteCount)) * 100)
  }
}

public extension PollDetail {
  static let mock = PollDetail(
    pollId: 1,
    titlePrefix: "도덕의 기준은",
    titleSuffix: "이다",
    targetDate: nil,
    status: .active,
    options: [
      .init(optionId: 1, label: "A", title: "결과", displayOrder: 1, voteCount: 45),
      .init(optionId: 2, label: "B", title: "의도", displayOrder: 2, voteCount: 25),
      .init(optionId: 3, label: "C", title: "규칙", displayOrder: 3, voteCount: 20),
      .init(optionId: 4, label: "D", title: "덕", displayOrder: 4, voteCount: 10),
    ]
  )
}
