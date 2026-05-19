//
//  PollDataDTO+.swift
//  Model
//

import Entity
import Foundation

private let pollDateFormatter: DateFormatter = {
  let f = DateFormatter()
  f.calendar = Calendar(identifier: .gregorian)
  f.locale = Locale(identifier: "en_US_POSIX")
  f.timeZone = TimeZone(secondsFromGMT: 0)
  f.dateFormat = "yyyy-MM-dd"
  return f
}()

public extension PollOptionDTO {
  func toDomain() -> PollOption {
    PollOption(
      optionId: optionId,
      label: label,
      title: title,
      displayOrder: displayOrder,
      voteCount: voteCount
    )
  }
}

public extension PollDataDTO {
  func toDomain() -> PollDetail {
    PollDetail(
      pollId: pollId,
      titlePrefix: titlePrefix,
      titleSuffix: titleSuffix,
      targetDate: targetDate.flatMap { pollDateFormatter.date(from: $0) },
      status: PollStatus(rawValue: status),
      options: options
        .sorted { $0.displayOrder < $1.displayOrder }
        .map { $0.toDomain() }
    )
  }
}
