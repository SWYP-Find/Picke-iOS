import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassResultDTO: Decodable, Sendable {
  struct Stats: Decodable, Sendable {
    struct Option: Decodable, Sendable {
      let optionId: Int
      let title: String
      let preVoteCount: Int
      let postVoteCount: Int
      let postVoteRatio: Double

      func toDomain() -> ClassResult.Option {
        ClassResult.Option(
          id: optionId,
          title: title,
          preVoteCount: preVoteCount,
          postVoteCount: postVoteCount,
          postVoteRatio: postVoteRatio
        )
      }
    }

    let activeMemberCount: Int
    let completedCount: Int
    let participationRate: Double
    let commentWriterCount: Int
    let commentRate: Double
    let postVoteCount: Int
    let options: [Option]

    func toDomain() -> ClassResult.Stats {
      ClassResult.Stats(
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

  let classId: Int
  let closeAt: String
  let closed: Bool
  let stats: Stats
  let myReportState: String?
  let insightState: String?

  func toDomain() throws -> ClassResult {
    guard let closeAt = closeAt.date(as: .serverDateTime) else {
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
