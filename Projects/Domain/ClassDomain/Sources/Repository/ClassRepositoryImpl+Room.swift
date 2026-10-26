import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func fetchMyClasses() async throws -> [ClassRoom] {
    do {
      let data = try await client.send(ClassroomService.myClasses, as: [ClassListItemDTO].self)
      return try data.map { try $0.toDomain() }
    } catch {
      throw Self.classError(error)
    }
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.create(creation), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(id: Int) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.unknown("참여 미리보기는 클래스 상세를 제공하지 않습니다.")
  }

  public func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    do {
      let data = try await client.send(
        ClassroomService.joinPreview(joinCode),
        as: ClassJoinPreviewDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    do {
      let data = try await client.send(
        ClassroomService.join(code: joinCode, nickname: nickname),
        as: ClassDetailDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    do {
      _ = try await client.send(
        ClassroomService.updateDeadline(id: id, deadline: deadline),
        as: PickeEmptyResponse.self
      )
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func deleteClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.delete(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  public func leaveClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.leave(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  private static func classError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    guard case let .response(response) = networkError else { return ClassError.from(networkError) }
    return ClassErrorMapper.map(
      code: response.code,
      message: response.message,
      fallback: "클래스 요청을 처리하지 못했습니다."
    )
  }}
