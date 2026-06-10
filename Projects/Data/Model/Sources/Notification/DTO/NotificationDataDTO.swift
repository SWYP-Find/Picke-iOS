//
//  NotificationDataDTO.swift
//  Model
//
//  `GET /api/v1/notifications` 및 단건 상세 응답 DTO.
//

import Foundation

public struct NotificationDataDTO: Decodable {
  public let items: [NotificationItemDTO]?
  public let hasNext: Bool?
}

public struct NotificationItemDTO: Decodable {
  public let notificationId: Int?
  public let category: String?
  public let detailCode: String?
  public let title: String?
  public let body: String?
  public let referenceId: Int?
  public let isRead: Bool?
  public let createdAt: String?
}

/// 단건 상세 (목록 항목 + readAt).
public struct NotificationDetailDTO: Decodable {
  public let notificationId: Int?
  public let category: String?
  public let detailCode: String?
  public let title: String?
  public let body: String?
  public let referenceId: Int?
  public let isRead: Bool?
  public let createdAt: String?
  public let readAt: String?
}

public typealias NotificationResponseDTO = BaseResponseDTO<NotificationDataDTO>
public typealias NotificationDetailResponseDTO = BaseResponseDTO<NotificationDetailDTO>
