import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassPerspectiveReceiptDTO {
  func toDomain() throws -> ClassPerspectiveReceipt {
    guard let createdAt = ServerDateParser.parse(createdAt) else {
      throw ClassBattleError.invalidResponse
    }
    return ClassPerspectiveReceipt(id: perspectiveId, status: status, createdAt: createdAt)
  }
}

extension ClassPerspectiveItemDTO.User {
  func toDomain() -> ClassPerspectiveAuthor {
    ClassPerspectiveAuthor(
      userTag: userTag,
      nickname: nickname,
      characterType: characterType,
      characterImageURL: characterImageUrl.flatMap(URL.init(string:))
    )
  }
}

extension ClassPerspectiveItemDTO.Option {
  func toDomain() -> ClassPerspectiveOption {
    ClassPerspectiveOption(id: optionId, label: label, title: title, stance: stance)
  }
}

extension ClassPerspectiveItemDTO {
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

extension ClassPerspectivePageDTO {
  func toDomain() throws -> ClassPerspectivePage {
    ClassPerspectivePage(
      items: try items.map { try $0.toDomain() },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}
