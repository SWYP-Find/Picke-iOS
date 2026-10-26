import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassResultDTO.Stats.Option {
  func toDomain() -> ClassResultOption {
    ClassResultOption(
      id: optionId,
      title: title,
      preVoteCount: preVoteCount,
      postVoteCount: postVoteCount,
      postVoteRatio: postVoteRatio
    )
  }
}

extension ClassResultDTO.Stats {
  func toDomain() -> ClassResultStats {
    ClassResultStats(
      activeMemberCount: activeMemberCount,
      completedCount: completedCount,
      participationRate: participationRate,
      commentWriterCount: commentWriterCount,
      commentRate: commentRate,
      postVoteCount: postVoteCount,
      options: options.map { $0.toDomain() }
    )
  }
}

extension ClassResultDTO {
  func toDomain() throws -> ClassResult {
    guard let closeAt = ServerDateParser.parse(closeAt) else {
      throw ClassError.network("클래스 마감일을 읽을 수 없습니다.")
    }
    return ClassResult(
      classID: classId,
      closed: closed,
      closeAt: closeAt,
      stats: stats.toDomain(),
      myReportState: myReportState,
      insightState: insightState
    )
  }
}
