import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassPerspectiveReceiptDTO: Decodable, Sendable {
  let perspectiveId: Int
  let status: String
  let createdAt: String
}

struct ClassPerspectiveItemDTO: Decodable, Sendable {
  struct User: Decodable, Sendable {
    let userTag: String
    let nickname: String
    let characterType: String?
    let characterImageUrl: String?

  }

  struct Option: Decodable, Sendable {
    let optionId: Int
    let label: String
    let title: String
    let stance: String?

  }

  let perspectiveId: Int
  let user: User
  let option: Option
  let content: String
  let likeCount: Int
  let commentCount: Int
  let isLiked: Bool
  let isMyPerspective: Bool?
  let status: String?
  let createdAt: String
}

struct ClassPerspectivePageDTO: Decodable, Sendable {
  let items: [ClassPerspectiveItemDTO]
  let nextCursor: String?
  let hasNext: Bool
}
