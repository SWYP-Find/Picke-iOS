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

        func toDomain() -> ClassBattleOption {
          ClassBattleOption(
            id: optionId,
            label: label,
            title: title,
            stance: stance ?? "",
            representative: representative ?? "",
            imageURL: imageUrl.flatMap(URL.init(string:))
          )
        }
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

    func toDomain() throws -> ClassBattleDetail {
      guard let currentStep = ClassBattleStep(rawValue: currentStep ?? "NONE") else {
        throw ClassBattleError.invalidResponse
      }
      return ClassBattleDetail(
        id: battleInfo.battleId,
        title: battleInfo.title,
        summary: battleInfo.summary ?? "",
        thumbnailURL: battleInfo.thumbnailUrl.flatMap(URL.init(string:)),
        description: description ?? "",
        shareURL: shareUrl.flatMap(URL.init(string:)),
        userVoteStatus: userVoteStatus,
        currentStep: currentStep,
        participantsCount: battleInfo.participantsCount ?? 0,
        audioDuration: battleInfo.audioDuration ?? 0,
        options: battleInfo.options.map { $0.toDomain() }
      )
    }
  }

  let classId: Int
  let myRole: String
  let closeAt: String
  let closed: Bool
  let commentRequired: Bool
  let canParticipate: Bool
  let participationCompleted: Bool
  let battle: Battle

  func toDomain() throws -> ClassBattleSession {
    let role: ClassRole
    switch myRole {
    case "OWNER": role = .owner
    case "MEMBER": role = .member
    default: throw ClassBattleError.invalidResponse
    }
    guard let closeAt = ServerDateParser.parse(closeAt) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassBattleSession(
      classID: classId,
      myRole: role,
      closeAt: closeAt,
      closed: closed,
      commentRequired: commentRequired,
      canParticipate: canParticipate,
      participationCompleted: participationCompleted,
      battle: try battle.toDomain()
    )
  }
}
