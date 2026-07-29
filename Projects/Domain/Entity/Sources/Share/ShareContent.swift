//
//  ShareContent.swift
//  Entity
//

import Foundation

public struct ShareContent: Equatable {
  public let title: String
  public let summary: String
  public let hashtags: [String]
  public let optionLine: String?
  public let url: String
  public let thumbnailURL: String?
  public let snapshotData: Data?

  public init(
    title: String,
    summary: String,
    hashtags: [String],
    optionLine: String?,
    url: String,
    thumbnailURL: String?,
    snapshotData: Data?
  ) {
    self.title = title
    self.summary = summary
    self.hashtags = hashtags
    self.optionLine = optionLine
    self.url = url
    self.thumbnailURL = thumbnailURL
    self.snapshotData = snapshotData
  }

  /// SNS / 메시지 공유 시 동행되는 본문 텍스트.
  /// 빈 섹션은 자동으로 건너뛴다.
  public var displayText: String {
    var lines: [String] = []
    if !title.isEmpty { lines.append(title) }
    if !summary.isEmpty { lines.append(summary) }
    if let optionLine, !optionLine.isEmpty { lines.append(optionLine) }
    let joinedHashtags = hashtags.joined(separator: " ")
    if !joinedHashtags.isEmpty { lines.append(joinedHashtags) }
    return lines.joined(separator: "\n\n")
  }
}
