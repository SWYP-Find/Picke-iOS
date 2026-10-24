public struct UnavailableClassBattleRepository: ClassBattleInterface {
  public init() {}

  public func fetchBattle(classID _: Int) async throws -> ClassBattleSession { throw ClassBattleError.invalidResponse }
  public func submitPreVote(
    classID _: Int,
    optionID _: Int
  ) async throws -> ClassVoteReceipt { throw ClassBattleError.invalidResponse }
  public func completeTTS(classID _: Int) async throws { throw ClassBattleError.invalidResponse }
  public func submitPostVote(
    classID _: Int,
    optionID _: Int
  ) async throws -> ClassVoteReceipt { throw ClassBattleError.invalidResponse }
  public func fetchMyVotes(classID _: Int) async throws -> ClassVoteHistory { throw ClassBattleError.invalidResponse }
  public func fetchVoteStats(classID _: Int) async throws -> ClassVoteStats { throw ClassBattleError.invalidResponse }
  public func publishPerspective(
    classID _: Int,
    content _: String
  ) async throws -> ClassPerspectiveReceipt { throw ClassBattleError.invalidResponse }
  public func fetchPerspectives(
    classID _: Int,
    cursor _: String?,
    size _: Int?,
    optionID _: Int?,
    sort _: String?
  ) async throws -> ClassPerspectivePage { throw ClassBattleError.invalidResponse }
  public func fetchMyPerspectives(classID _: Int) async throws -> [ClassPerspectiveItem] { throw ClassBattleError.invalidResponse }
}
