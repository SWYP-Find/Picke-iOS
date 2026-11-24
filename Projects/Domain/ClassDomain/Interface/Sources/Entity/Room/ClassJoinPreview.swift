import Foundation

public struct ClassJoinPreview: Equatable, Sendable {
  public let inviteCode: String
  public let name: String
  public let battleTitle: String
  public let battleThumbnailURL: URL?
  public let battleType: String
  public let memberCount: Int
  public let activeMemberCount: Int
  public let capacity: Int
  public let closeAt: Date

  public init(
    inviteCode: String,
    name: String,
    battleTitle: String,
    battleThumbnailURL: URL?,
    battleType: String,
    memberCount: Int,
    activeMemberCount: Int? = nil,
    capacity: Int,
    closeAt: Date
  ) {
    self.inviteCode = inviteCode
    self.name = name
    self.battleTitle = battleTitle
    self.battleThumbnailURL = battleThumbnailURL
    self.battleType = battleType
    self.memberCount = memberCount
    self.activeMemberCount = activeMemberCount ?? memberCount
    self.capacity = capacity
    self.closeAt = closeAt
  }

  public init(room: ClassRoom) {
    self.init(
      inviteCode: room.joinCode,
      name: room.name,
      battleTitle: room.battle.title,
      battleThumbnailURL: room.battle.thumbnailURL,
      battleType: room.battleType.rawValue,
      memberCount: room.memberCount,
      activeMemberCount: room.activeMemberCount,
      capacity: room.memberCapacity ?? 0,
      closeAt: room.deadline
    )
  }
}
