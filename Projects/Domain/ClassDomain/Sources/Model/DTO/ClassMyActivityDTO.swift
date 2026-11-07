import Foundation

struct ClassMyActivityDTO: Decodable, Sendable {
  struct Comment: Decodable, Sendable {
    let commentId: Int?
    let perspectiveId: Int?
    let perspectiveTitle: String?
    let stance: String?
    let content: String?
    let likeCount: Int?
    let createdAt: String?
  }

  let classId: Int?
  let receivedLikeCount: Int?
  let commentCount: Int?
  let comments: [Comment]?
  let nextCursor: String?
  let hasNext: Bool?
}
