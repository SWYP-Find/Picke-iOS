import ClassDomainInterface
import Foundation

/// 운영 경로에서는 서버에 연결되지 않은 기능을 성공으로 가장하지 않는다.
struct ClassLiveRepository: ClassInterface {
  let api: any ClassInterface

  func fetchMyClasses() async throws -> [ClassRoom] {
    try await api.fetchMyClasses()
  }

  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await api.fetchRecommendedBattles(filter: filter)
  }

  func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await api.createClass(creation)
  }

  func fetchClass(id: Int) async throws -> ClassRoom {
    try await api.fetchClass(id: id)
  }

  func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await api.fetchClass(joinCode: joinCode)
  }

  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    try await api.fetchClassPreview(joinCode: joinCode)
  }

  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await api.joinClass(joinCode: joinCode, nickname: nickname)
  }

  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await api.updateDeadline(id: id, deadline: deadline)
  }

  func deleteClass(id: Int) async throws {
    try await api.deleteClass(id: id)
  }

  func leaveClass(id: Int) async throws {
    try await api.leaveClass(id: id)
  }

  func fetchReport(roomID: Int) async throws -> ClassReport? {
    try await api.fetchReport(roomID: roomID)
  }

  func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData? {
    try await api.fetchOwnerDashboard(roomID: roomID)
  }
}
