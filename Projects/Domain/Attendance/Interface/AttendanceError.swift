//
//  AttendanceError.swift
//  Entity
//
//  출석체크 도메인 표준 에러.
//

import Foundation

public enum AttendanceError: LocalizedError, Equatable {
  case networkError(String)
  case decodingError(String)
  case noData
  case unauthorized
  /// 하루 1회 제한에 걸린 경우 — 서버가 중복 출석을 거절.
  case alreadyCheckedIn
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
      "출석 데이터가 없습니다"
    case .unauthorized:
      "권한이 없습니다"
    case .alreadyCheckedIn:
      "오늘은 이미 출석했습니다"
    case let .backendError(message):
      "출석 처리 실패: \(message)"
    case let .serverError(code):
      "서버 오류 (코드: \(code))"
    case let .unknown(message):
      "알 수 없는 오류: \(message)"
    }
  }
}

public extension AttendanceError {
  static func from(_ error: Error) -> AttendanceError {
    if let attendanceError = error as? AttendanceError { return attendanceError }
    return .unknown(error.localizedDescription)
  }
}
