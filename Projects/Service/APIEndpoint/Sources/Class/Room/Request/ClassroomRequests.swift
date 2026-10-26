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

  init(creation: ClassCreation) {
    name = creation.name
    battleId = creation.battleId
    topicVersionId = creation.topicVersionId
    deadline = creation.deadline == .distantFuture
      ? nil
      : creation.deadline.formatted(.serverDateTime)
    commentRequired = creation.requiresComment
    ownerParticipates = creation.ownerParticipates
  }
}

struct UpdateClassBody: Encodable, Sendable {
  let deadline: String
}

struct ClassJoinPreviewQuery: Encodable, Sendable {
  let inviteCode: String
}

struct JoinClassBody: Encodable, Sendable {
  let inviteCode: String
  let displayName: String
}
