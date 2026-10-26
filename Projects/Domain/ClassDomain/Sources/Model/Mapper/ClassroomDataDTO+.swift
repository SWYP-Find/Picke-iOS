import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassListItemDTO {
  func toDomain() throws -> ClassRoom {
    let closeDate = try closeAt.classDate()
    return ClassRoom(
      id: classId,
      name: name,
      joinCode: "",
      battle: .classProjection(id: battleId, title: battleTitle, thumbnailUrl: battleThumbnailUrl),
      deadline: .distantFuture,
      closeAt: closeDate,
      memberCount: memberCount,
      role: try myRole.classRole(),
      status: closed ? .closed : .open,
      allowsAnonymousOpinion: false,
      requiresComment: false,
      memberCapacity: capacity,
      battleType: battleType
    )
  }
}

extension ClassDetailDataDTO {
  func toDomain() throws -> ClassRoom {
    return ClassRoom(
      id: classId,
      name: name,
      joinCode: inviteCode ?? "",
      battle: .classProjection(
        id: battle.battleId,
        title: battle.title,
        summary: battle.summary ?? "",
        thumbnailUrl: battle.thumbnailUrl
      ),
      deadline: try deadline.map { try $0.classDate() } ?? .distantFuture,
      closeAt: try closeAt.classDate(),
      memberCount: memberCount,
      role: try myRole.classRole(),
      status: closed ? .closed : .open,
      allowsAnonymousOpinion: false,
      requiresComment: commentRequired,
      ownerParticipates: ownerParticipates,
      memberCapacity: capacity,
      battleType: battleType,
      ticketExpiresAt: try ticketExpiresAt.classDate()
    )
  }
}

extension ClassJoinPreviewDataDTO {
  func toDomain() throws -> ClassJoinPreview {
    ClassJoinPreview(
      inviteCode: inviteCode,
      name: name,
      battleTitle: battleTitle,
      battleThumbnailURL: battleThumbnailUrl.flatMap(URL.init(string:)),
      battleType: battleType,
      memberCount: memberCount,
      capacity: capacity,
      closeAt: try closeAt.classDate()
    )
  }
}

private extension ClassBattleSummary {
  static func classProjection(
    id: Int,
    title: String,
    summary: String = "",
    thumbnailUrl: String?
  ) -> Self {
    ClassBattleSummary(
      id: id,
      title: title,
      summary: summary,
      thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
      philosopherA: "",
      optionATitle: "",
      philosopherB: "",
      optionBTitle: "",
      category: .philosophy,
      categoryDisplayTitle: "",
      level: .middle,
      audioDuration: 0,
      viewCount: 0
    )
  }
}

private extension String {
  func classDate() throws -> Date {
    guard let date = date(as: .serverDateTime) else {
      throw ClassError.unknown("클래스 날짜 형식을 읽을 수 없습니다: \(self)")
    }
    return date
  }

  func classRole() throws -> ClassRole {
    switch self {
    case "OWNER": return .owner
    case "MEMBER": return .member
    default: throw ClassError.unknown("알 수 없는 클래스 역할: \(self)")
    }
  }
}
