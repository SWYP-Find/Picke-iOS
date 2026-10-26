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

    }

    let activeMemberCount: Int
    let completedCount: Int
    let participationRate: Double
    let commentWriterCount: Int
    let commentRate: Double
    let postVoteCount: Int
    let options: [Option]

  }

  let classId: Int
  let closeAt: String
  let closed: Bool
  let stats: Stats
  let myReportState: String?
  let insightState: String?
}
