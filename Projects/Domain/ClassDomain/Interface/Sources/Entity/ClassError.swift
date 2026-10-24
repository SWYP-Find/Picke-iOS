//
//  ClassError.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum ClassError: LocalizedError, Equatable, Sendable {
  case invalidCode
  case closed
  case alreadyJoined
  case duplicateName
  case accessDenied
  case resultExpired
  case network(String)
  case unknown(String)

  public var errorDescription: String? {
    message
  }

  public var message: String {
    switch self {
    case .invalidCode: return "참여 코드를 다시 확인해 주세요."
    case .closed: return "종료된 클래스입니다."
    case .alreadyJoined: return "이미 참여한 클래스입니다."
    case .duplicateName: return "이미 사용 중인 이름이에요."
    case .accessDenied: return "클래스 결과를 볼 권한이 없어요."
    case .resultExpired: return "결과 열람 기간이 끝났습니다."
    case let .network(message), let .unknown(message): return message
    }
  }

  public static func from(_ error: Error) -> ClassError {
    if let error = error as? ClassError {
      return error
    }
    if let error = error as? URLError {
      return .network(error.localizedDescription)
    }
    return .unknown(String(describing: error))
  }
}
