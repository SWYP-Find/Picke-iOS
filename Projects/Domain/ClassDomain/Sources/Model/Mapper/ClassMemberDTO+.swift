import ClassDomainInterface
import Foundation

extension ClassMemberDTO {
  func toDomain() -> ClassMember {
    ClassMember(
      id: memberId,
      name: displayName,
      isOwner: role == "OWNER",
      characterURL: characterUrl
    )
  }
}

extension ClassMemberDTO {
  static func toMemberList(_ payload: [Self]) -> ClassMemberList {
    // 서버는 참여하지 않은 운영자 행을 명단에 넣지 않는다. 내 행이 없어도 명단은 보여준다(Android 동일).
    ClassMemberList(
      members: payload.map { $0.toDomain() },
      currentMemberID: payload.first(where: \.me)?.memberId
    )
  }
}
