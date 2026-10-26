import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassBattleSessionDTO: Decodable, Sendable {
  struct Battle: Decodable, Sendable {
    struct Info: Decodable, Sendable {
      struct Option: Decodable, Sendable {
        let optionId: Int
        let label: String?
        let title: String
        let stance: String?
        let representative: String?
        let imageUrl: String?

      }

      let battleId: Int
      let title: String
      let summary: String?
      let thumbnailUrl: String?
      let participantsCount: Int?
      let audioDuration: Int?
      let options: [Option]
    }

    let battleInfo: Info
    let description: String?
    let shareUrl: String?
    let userVoteStatus: String?
    let currentStep: String?

  }

  let classId: Int
  let myRole: String
  let closeAt: String
  let closed: Bool
  let commentRequired: Bool
  let canParticipate: Bool
  let participationCompleted: Bool
  let battle: Battle
}
