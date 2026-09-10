//
//  BattleError.swift
//  BattleDomainInterface
//

import Foundation

public enum BattleError: LocalizedError, Equatable {
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
      "배틀 데이터가 없습니다"
    case .unauthorized:
      "권한이 없습니다"
    case let .backendError(message):
      "배틀 처리 실패: \(message)"
    case let .serverError(code):
      "서버 오류 (코드: \(code))"
    case let .unknown(message):
      "알 수 없는 오류: \(message)"
    }
  }

  public var failureReason: String? {
    switch self {
    case .networkError:
      "네트워크 연결을 확인해주세요"
    case .decodingError:
      "서버 응답 데이터가 올바르지 않습니다"
    case .noData:
      "조회된 배틀 정보가 없습니다"
    case .unauthorized:
      "로그인이 필요합니다"
    case .backendError:
      "백엔드 응답에서 비즈니스 오류가 보고되었습니다"
    case .serverError:
      "잠시 후 다시 시도해주세요"
    case .unknown:
      "예상치 못한 오류가 발생했습니다"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .networkError:
      "인터넷 연결을 확인하고 다시 시도해주세요"
    case .decodingError:
      "앱을 다시 시작해보세요"
    case .noData:
      "새로고침하거나 관리자에게 문의하세요"
    case .unauthorized:
      "다시 로그인해주세요"
    case .backendError:
      "다른 옵션을 선택하거나 잠시 후 다시 시도해주세요"
    case .serverError:
      "잠시 후 다시 시도하거나 고객센터에 문의하세요"
    case .unknown:
      "문제가 지속되면 고객센터에 문의해주세요"
    }
  }
}

public extension BattleError {
  static func from(_ error: Error) -> BattleError {
    if let battleError = error as? BattleError { return battleError }
    return .unknown(error.localizedDescription)
  }
}
