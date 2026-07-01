//
//  EngagementAction.swift
//  UseCase
//
//  engagement_action(Tier3) 의 미세 상호작용 종류.
//

import Foundation

public enum EngagementAction: String, Sendable {
  case commentLike = "comment_like"
  case replyWrite = "reply_write"
  case commentReport = "comment_report"
}
