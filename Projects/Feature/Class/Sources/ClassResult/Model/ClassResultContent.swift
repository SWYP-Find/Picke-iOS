//
//  ClassResultContent.swift
//  Class
//
//  Created by Picke on 11/20/26.
//

import ClassDomainInterface
import Foundation

/// 결과 화면에 그리는 불러온 내용. 탭 노출 여부는 서버 인사이트·내 리포트 상태로 정한다.
public struct ClassResultContent: Equatable, Sendable {
  public var className: String
  public var isInProgress: Bool
  public var tag: String
  public var battleTitle: String
  public var deadline: Date
  public var hasSummaryTab: Bool
  public var hasReportTab: Bool
  public var stats: ClassResultStats
  public var insight: ClassResultInsightBoard?
  public var report: ClassResultMyReportBoard?
  public var receivedLikeCount: Int?
}
