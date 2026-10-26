import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassListItemDTO: Decodable, Sendable {
  let classId: Int
  let name: String
  let myRole: String
  let battleId: Int
  let battleTitle: String
  let battleThumbnailUrl: String?
  let battleType: ClassBattleType
  let memberCount: Int
  let capacity: Int
  let closeAt: String
  let closed: Bool
}

struct ClassDetailDataDTO: Decodable, Sendable {
  struct Battle: Decodable, Sendable {
    let battleId: Int
    let title: String
    let summary: String?
    let thumbnailUrl: String?
  }

  let classId: Int
  let name: String
  let inviteCode: String?
  let myRole: String
  let battle: Battle
  let battleType: ClassBattleType
  let memberCount: Int
  let capacity: Int
  let deadline: String?
  let ticketExpiresAt: String
  let closeAt: String
  let closed: Bool
  let commentRequired: Bool
  let ownerParticipates: Bool
}

struct ClassJoinPreviewDataDTO: Decodable, Sendable {
  let inviteCode: String
  let name: String
  let battleTitle: String
  let battleThumbnailUrl: String?
  let battleType: String
  let memberCount: Int
  let capacity: Int
  let closeAt: String
}
