import ClassDomainInterface
import Foundation

/// 아직 서버에 연결되지 않은 클래스 기능은 공유 목 상태를 유지한다.
struct ClassLiveRepository: ClassInterface {
  let mock: any ClassInterface
  let recommendations: any ClassInterface

  func fetchMyClasses() async throws -> [ClassRoom] {
    try await mock.fetchMyClasses()
  }

  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await recommendations.fetchRecommendedBattles(filter: filter)
  }

  func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await mock.createClass(creation)
  }

  func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await mock.fetchClass(joinCode: joinCode)
  }

  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await mock.joinClass(joinCode: joinCode, nickname: nickname)
  }

  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await mock.updateDeadline(id: id, deadline: deadline)
  }

  func deleteClass(id: Int) async throws {
    try await mock.deleteClass(id: id)
  }

  func leaveClass(id: Int) async throws {
    try await mock.leaveClass(id: id)
  }

  func fetchReport(roomID: Int) async throws -> ClassReport? {
    try await mock.fetchReport(roomID: roomID)
  }

  func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData? {
    try await mock.fetchOwnerDashboard(roomID: roomID)
  }
}
