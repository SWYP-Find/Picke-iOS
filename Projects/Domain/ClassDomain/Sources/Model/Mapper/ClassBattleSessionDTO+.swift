import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassBattleSessionDTO.Battle.Info.Option {
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

extension ClassBattleSessionDTO.Battle {
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

extension ClassBattleSessionDTO {
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
