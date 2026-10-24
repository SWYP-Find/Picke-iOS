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
  case notFound
  case full
  case deleted
  case ownClass
  case removed
  case ticketRequired
  case ownerOnly
  case memberOnly
  case ownerCannotLeave
  case memberNotFound
  case invalidDeadline
  case deadlineExtensionOnly
  case invalidBattle
  case topicVersionNotFound
  case topicDraftUsed
  case inviteCodeFailed
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
    case .notFound: return "존재하지 않는 클래스입니다."
    case .full: return "정원이 가득 찬 클래스입니다."
    case .deleted: return "삭제되어 더 이상 이용할 수 없는 클래스입니다."
    case .ownClass: return "내가 운영하는 클래스에는 참여자로 들어갈 수 없습니다."
    case .removed: return "내보내진 클래스에는 다시 참여할 수 없습니다."
    case .ticketRequired: return "사용 중인 이용권이 없어 클래스를 만들 수 없습니다."
    case .ownerOnly: return "클래스 운영자만 할 수 있습니다."
    case .memberOnly: return "클래스 멤버만 볼 수 있습니다."
    case .ownerCannotLeave: return "운영자는 클래스를 나가거나 내보내질 수 없습니다. 클래스를 삭제해 주세요."
    case .memberNotFound: return "존재하지 않는 멤버입니다."
    case .invalidDeadline: return "마감일은 현재 시각 이후, 이용권 종료일 이전이어야 합니다."
    case .deadlineExtensionOnly: return "마감일은 기존 마감일보다 뒤로 연장만 할 수 있습니다."
    case .invalidBattle: return "클래스에 사용할 수 없는 배틀입니다."
    case .topicVersionNotFound: return "존재하지 않는 주제 버전입니다."
    case .topicDraftUsed: return "이 주제 초안으로 이미 만든 클래스가 있습니다."
    case .inviteCodeFailed: return "초대코드 생성에 실패했습니다. 다시 시도해 주세요."
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
