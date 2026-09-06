//
//  ReportReason.swift
//  DesignSystem
//
//  신고 사유 enum

import Foundation

public enum ReportReason: String, CaseIterable, Identifiable, Equatable {
  case commercial
  case repeat_
  case explicit
  case insult
  case other

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .commercial: "영리목적/홍보성"
    case .repeat_: "같은 내용 반복 게시"
    case .explicit: "음란성/선정성"
    case .insult: "욕설/인신공격"
    case .other: "기타"
    }
  }

  static let leftColumn: [ReportReason] = [.commercial, .explicit, .other]
  static let rightColumn: [ReportReason] = [.repeat_, .insult]
}
