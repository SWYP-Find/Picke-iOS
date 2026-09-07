//
//  NotificationItem.swift
//  Entity
//

import Foundation

public struct NotificationItem: Equatable, Identifiable {
  public let notificationId: Int
  public let category: NotificationCategory
  /// 세부 유형 코드 (서버 정의 문자열).
  public let detailCode: String
  /// 상단 보조 문구 (예: "새로운 배틀이 시작되었어요").
  public let title: String
  /// 본문 (예: "“AI가 만든 그림도 예술인가?”에 지금 참여해보세요!").
  public let body: String
  /// 연관 리소스 id (배틀=battleId / 답글=commentId 등). 없을 수 있음.
  public let referenceId: Int?
  /// COMMENT_LIKE / NEW_COMMENT 에서 관점(댓글) 화면 이동용. 그 외 nil.
  public let perspectiveId: Int?
  public let isRead: Bool
  public let createdAt: Date?

  public var id: Int { notificationId }

  public init(
    notificationId: Int,
    category: NotificationCategory,
    detailCode: String,
    title: String,
    body: String,
    referenceId: Int?,
    perspectiveId: Int?,
    isRead: Bool,
    createdAt: Date?
  ) {
    self.notificationId = notificationId
    self.category = category
    self.detailCode = detailCode
    self.title = title
    self.body = body
    self.referenceId = referenceId
    self.perspectiveId = perspectiveId
    self.isRead = isRead
    self.createdAt = createdAt
  }

  /// 카테고리 기반 표시 아이콘 (SF Symbol).
  public var iconSystemName: String {
    switch category {
    case .content: "flame"
    case .notice: "speaker.wave.2"
    case .event: "gift"
    case .all: "bell"
    }
  }

  /// 읽음 처리된 사본.
  public func markedAsRead() -> NotificationItem {
    NotificationItem(
      notificationId: notificationId,
      category: category,
      detailCode: detailCode,
      title: title,
      body: body,
      referenceId: referenceId,
      perspectiveId: perspectiveId,
      isRead: true,
      createdAt: createdAt
    )
  }
}
