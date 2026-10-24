import ClassDomainInterface
import Foundation

struct ClassMemberDTO: Decodable, Sendable {
  let memberId: Int
  let displayName: String
  let role: String
  let characterUrl: URL?
  let me: Bool

  func toDomain() -> ClassMember {
    ClassMember(
      id: memberId,
      name: displayName,
      isOwner: role == "OWNER",
      characterURL: characterUrl
    )
  }

  static func toMemberList(_ payload: [Self]) throws -> ClassMemberList {
    guard let current = payload.first(where: \.me) else {
      throw ClassError.unknown("내 멤버 정보를 찾을 수 없어요.")
    }
    return ClassMemberList(
      members: payload.map { $0.toDomain() },
      currentMemberID: current.memberId
    )
  }
}
