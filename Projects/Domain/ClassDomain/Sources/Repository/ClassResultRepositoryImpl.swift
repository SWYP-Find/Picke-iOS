import ClassDomainInterface
import Dependencies
import PickeNetwork

public struct ClassResultRepositoryImpl: ClassResultInterface {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetch(roomID: Int) async throws -> ClassResult {
    do {
      let payload = try await client.send(ClassResultService.result(roomID), as: ClassResultDTO.self)
      return try payload.toDomain()
    } catch {
      throw ClassError.from(error)
    }
  }

  public func fetchPersonal(roomID: Int) async throws -> ClassAIPersonalFeedback {
    do {
      let payload = try await client.send(ClassResultService.myReport(roomID), as: ClassPersonalReportDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.feedbackError(error)
    }
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    do {
      let payload = try await client.send(ClassResultService.insight(roomID), as: ClassInsightDTO.self)
      return try payload.toDomain()
    } catch {
      throw Self.feedbackError(error)
    }
  }

  public func retryInsight(roomID: Int) async throws {
    do {
      let payload = try await client.send(ClassResultService.retryInsight(roomID), as: ClassInsightRetryDTO.self)
      guard payload.state == "PENDING" else { throw ClassAIFeedbackError.generationFailed }
    } catch {
      throw Self.feedbackError(error)
    }
  }

  private static func feedbackError(_ error: Error) -> ClassAIFeedbackError {
    if let mapped = error as? ClassAIFeedbackError { return mapped }
    if let networkError = error as? PickeNetworkError,
       case let .response(response) = networkError
    {
      switch response.code {
      case "CLASS_409_REPORT_RETRY": return .generationFailed
      case "CLASS_409_RESULT_EXPIRED", "CLASS_403_MEMBER", "CLASS_403_OWNER": return .insufficientInput
      default: return .temporarilyUnavailable
      }
    }
    return .temporarilyUnavailable
  }
}
