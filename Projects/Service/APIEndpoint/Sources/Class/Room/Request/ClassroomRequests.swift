import Foundation
import ClassDomainInterface
import PickeCoreUtility

struct CreateClassBody: Encodable, Sendable {
  let name: String
  let battleId: Int?
  let topicVersionId: Int?
  let deadline: String?
  let commentRequired: Bool
  let ownerParticipates: Bool
  let ownerDisplayName: String?
  let requestKey: String?

  init(creation: ClassCreation) {
    name = creation.name
    battleId = creation.battleId
    topicVersionId = creation.topicVersionId
    deadline = creation.deadline == .distantFuture
      ? nil
      : creation.deadline.formatted(.serverDateTime)
    commentRequired = creation.requiresComment
    ownerParticipates = creation.ownerParticipates
    ownerDisplayName = creation.ownerDisplayName
    requestKey = creation.requestKey
  }
}

struct UpdateClassBody: Encodable, Sendable {
  let name: String?
  let deadline: String?
}

struct ClassJoinPreviewQuery: Encodable, Sendable {
  let inviteCode: String
}

struct JoinClassBody: Encodable, Sendable {
  let inviteCode: String
  let displayName: String
}
