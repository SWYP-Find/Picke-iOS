//
//  EngagementAction.swift
//  UseCase
//

import Foundation

public enum EngagementAction: String, Sendable {
  case commentLike = "comment_like"
  case replyWrite = "reply_write"
  case commentReport = "comment_report"
}
