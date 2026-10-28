//
//  ClassErrorMapper.swift
//  ClassDomain
//
//  Created by Picke on 10/24/26.
//

import ClassDomainInterface
import Foundation

/// 클래스 생성·조회·참여·멤버 API 의 서버 에러 코드(명세 10장)를 `ClassError` 로 바꾼다.
/// 매핑에 없는 코드는 서버 메시지를, 메시지도 없으면 `fallback` 을 그대로 보여준다.
enum ClassErrorMapper {
  static func map(
    code: String?,
    message: String?,
    fallback: String
  ) -> ClassError {
    if let mapped = code.flatMap(classError(code:)) {
      return mapped
    }
    return .network(message ?? fallback)
  }

  private static func classError(code: String) -> ClassError? {
    switch code {
    case "CLASS_404_CODE": return .invalidCode
    case "CLASS_409_CLOSED", "CLASS_409_TICKET_ENDED": return .closed
    case "CLASS_409_JOINED": return .alreadyJoined
    case "CLASS_409_NAME": return .duplicateName
    case "CLASS_404": return .notFound
    case "CLASS_409_FULL": return .full
    case "CLASS_409_DELETED": return .deleted
    case "CLASS_409_REQUEST_KEY": return .requestKeyConflict
    case "CLASS_409_OWNER": return .ownClass
    case "CLASS_403_REMOVED": return .removed
    case "CLASS_403_TICKET": return .ticketRequired
    case "CLASS_403_OWNER": return .ownerOnly
    case "CLASS_403_MEMBER": return .memberOnly
    case "CLASS_403_OWNER_LEAVE": return .ownerCannotLeave
    case "CLASS_404_MEMBER": return .memberNotFound
    case "CLASS_400_DEADLINE": return .invalidDeadline
    case "CLASS_400_DEADLINE_EXT": return .deadlineExtensionOnly
    case "CLASS_400_BATTLE": return .invalidBattle
    case "CLASS_404_TOPIC_VERSION": return .topicVersionNotFound
    case "CLASS_409_TOPIC_DRAFT_USED": return .topicDraftUsed
    case "CLASS_500_CODE": return .inviteCodeFailed
    default: return nil
    }
  }
}
