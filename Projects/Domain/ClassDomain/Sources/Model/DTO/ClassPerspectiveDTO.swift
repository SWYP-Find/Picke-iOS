import ClassDomainInterface
import Foundation
import PickeCoreUtility

struct ClassPerspectiveReceiptDTO: Decodable, Sendable {
  let perspectiveId: Int
  let status: String
  let createdAt: String

  func toDomain() throws -> ClassPerspectiveReceipt {
    guard let createdAt = ServerDateParser.parse(createdAt) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassPerspectiveReceipt(id: perspectiveId, status: status, createdAt: createdAt)
  }
}

struct ClassPerspectiveItemDTO: Decodable, Sendable {
  struct User: Decodable, Sendable {
    let userTag: String
    let nickname: String
    let characterType: String?
    let characterImageUrl: String?

    func toDomain() -> ClassPerspectiveAuthor {
      ClassPerspectiveAuthor(
        userTag: userTag,
        nickname: nickname,
        characterType: characterType,
        characterImageURL: characterImageUrl.flatMap(URL.init(string:))
      )
    }
  }

  struct Option: Decodable, Sendable {
    let optionId: Int
    let label: String
    let title: String
    let stance: String?

    func toDomain() -> ClassPerspectiveOption {
      ClassPerspectiveOption(id: optionId, label: label, title: title, stance: stance)
    }
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

  func toDomain() throws -> ClassPerspectiveItem {
    guard let createdAt = ServerDateParser.parse(createdAt) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassPerspectiveItem(
      id: perspectiveId,
      author: user.toDomain(),
      option: option.toDomain(),
      content: content,
      likeCount: likeCount,
      commentCount: commentCount,
      isLiked: isLiked,
      isMyPerspective: isMyPerspective,
      status: status,
      createdAt: createdAt
    )
  }
}

struct ClassPerspectivePageDTO: Decodable, Sendable {
  let items: [ClassPerspectiveItemDTO]
  let nextCursor: String?
  let hasNext: Bool

  func toDomain() throws -> ClassPerspectivePage {
    ClassPerspectivePage(
      items: try items.map { try $0.toDomain() },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}
