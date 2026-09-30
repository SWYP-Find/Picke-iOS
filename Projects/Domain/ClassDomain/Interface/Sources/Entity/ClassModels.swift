import Foundation

public enum ClassRole: String, Equatable, Sendable {
  case owner
  case member
}

public enum ClassStatus: String, Equatable, Sendable {
  case open
  case closed
}

public struct ClassRoom: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let joinCode: String
  public let battleId: Int
  public let battleTitle: String
  public let deadline: Date
  public let memberCount: Int
  public let role: ClassRole
  public let status: ClassStatus
  public let isVoteEnabled: Bool
  public let requiresComment: Bool

  public init(
    id: Int,
    name: String,
    joinCode: String,
    battleId: Int,
    battleTitle: String,
    deadline: Date,
    memberCount: Int,
    role: ClassRole,
    status: ClassStatus,
    isVoteEnabled: Bool,
    requiresComment: Bool
  ) {
    self.id = id
    self.name = name
    self.joinCode = joinCode
    self.battleId = battleId
    self.battleTitle = battleTitle
    self.deadline = deadline
    self.memberCount = memberCount
    self.role = role
    self.status = status
    self.isVoteEnabled = isVoteEnabled
    self.requiresComment = requiresComment
  }
}

public struct ClassTopicFilter: Equatable, Sendable {
  public var keyword: String
  public var level: String?
  public var category: String?

  public init(
    keyword: String = "",
    level: String? = nil,
    category: String? = nil
  ) {
    self.keyword = keyword
    self.level = level
    self.category = category
  }
}

public struct ClassBattleSummary: Equatable, Identifiable, Sendable {
  public let id: Int
  public let title: String
  public let summary: String
  public let category: String
  public let thumbnailURL: URL?

  public init(
    id: Int,
    title: String,
    summary: String,
    category: String,
    thumbnailURL: URL?
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.category = category
    self.thumbnailURL = thumbnailURL
  }
}

public struct ClassCreation: Equatable, Sendable {
  public var name: String
  public var deadline: Date
  public var battleId: Int
  public var isVoteEnabled: Bool
  public var requiresComment: Bool

  public init(
    name: String,
    deadline: Date,
    battleId: Int,
    isVoteEnabled: Bool,
    requiresComment: Bool
  ) {
    self.name = name
    self.deadline = deadline
    self.battleId = battleId
    self.isVoteEnabled = isVoteEnabled
    self.requiresComment = requiresComment
  }
}

public enum ClassError: Error, Equatable, Sendable {
  case invalidCode
  case closed
  case alreadyJoined
  case network(String)
  case unknown(String)

  public static func from(_ error: Error) -> ClassError {
    if let error = error as? ClassError {
      return error
    }
    if let error = error as? URLError {
      return .network(error.localizedDescription)
    }
    return .unknown(String(describing: error))
  }
}
