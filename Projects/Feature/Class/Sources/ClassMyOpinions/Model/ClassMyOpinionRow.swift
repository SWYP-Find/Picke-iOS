//
//  ClassMyOpinionRow.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import ClassDomainInterface
import PickeCoreUtility

public struct ClassMyOpinionRow: Equatable, Identifiable {
  public let index: Int
  public let opinion: ClassReportOpinion

  public var id: Int { index }
  public var accessibilityID: String { "class-my-opinion-\(index)" }
  public var likesText: String? { opinion.likeCount?.decimalFormatted }
  public var repliesText: String? { opinion.replyCount?.decimalFormatted }
  public var likesAccessibilityLabel: String? { likesText.map { "좋아요 \($0)개" } }
  public var repliesAccessibilityLabel: String? { repliesText.map { "대댓글 \($0)개" } }
  public var replyAuthorLabel: String? { opinion.authorName.map { "\($0)의 답글" } }
  public var parentStanceLabel: String? {
    guard let parent = opinion.parent, let stance = parent.stance else { return nil }
    return parent.authorName == nil ? stance : "· \(stance)"
  }

  public init(
    index: Int,
    opinion: ClassReportOpinion
  ) {
    self.index = index
    self.opinion = opinion
  }
}
