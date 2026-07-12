//
//  PerspectiveError.swift
//  Entity
//

import Foundation

public enum PerspectiveError: LocalizedError, Equatable {
  case networkError(String)
  case decodingError(String)
  case noData
  case unauthorized
  case backendError(String)
  case serverError(Int)
  case unknown(String)

  public var errorDescription: String? {
    switch self {
    case let .networkError(message): return "네트워크 오류: \(message)"
    case let .decodingError(message): return "데이터 파싱 오류: \(message)"
    case .noData: return "perspective 데이터가 없습니다"
    case .unauthorized: return "권한이 없습니다"
    case let .backendError(message): return "perspective 처리 실패: \(message)"
    case let .serverError(code): return "서버 오류 (코드: \(code))"
    case let .unknown(message): return "알 수 없는 오류: \(message)"
    }
  }
}

public extension PerspectiveError {
  static func from(_ error: Error) -> PerspectiveError {
    if let perspectiveError = error as? PerspectiveError { return perspectiveError }
    return .unknown(error.localizedDescription)
  }
}
