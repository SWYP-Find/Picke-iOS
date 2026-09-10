//
//  NotificationError.swift
//  Entity
//

import Foundation

public enum NotificationError: LocalizedError, Equatable {
  case networkError(String)
  case decodingError(String)
  case noData
  case unauthorized
  case backendError(String)
  case serverError(Int)
  case unknown(String)

  public var errorDescription: String? {
    switch self {
    case let .networkError(message):
      "네트워크 오류: \(message)"
    case let .decodingError(message):
      "데이터 파싱 오류: \(message)"
    case .noData:
      "알림 데이터가 없습니다"
    case .unauthorized:
      "권한이 없습니다"
    case let .backendError(message):
      "알림 처리 실패: \(message)"
    case let .serverError(code):
      "서버 오류 (코드: \(code))"
    case let .unknown(message):
      "알 수 없는 오류: \(message)"
    }
  }
}

public extension NotificationError {
  static func from(_ error: Error) -> NotificationError {
    if let notificationError = error as? NotificationError { return notificationError }
    return .unknown(error.localizedDescription)
  }
}
