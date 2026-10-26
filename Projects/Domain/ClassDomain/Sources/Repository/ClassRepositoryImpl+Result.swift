//
//  ClassRepositoryImpl+Result.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func fetchResult(roomID: Int) async throws -> ClassResult {
    do {
      let payload = try await client.send(ClassResultService.result(roomID), as: ClassResultDTO.self)
      return try payload.toDomain()
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw Self.resultError(code: response.code, message: response.message)
      }
      throw ClassError.from(error)
    } catch {
      throw ClassError.from(error)
    }
  }

  public func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback {
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
      guard payload.state == .pending else { throw ClassAIFeedbackError.generationFailed }
    } catch {
      throw Self.feedbackError(error)
    }
  }

  static func resultError(
    code: String?,
    message: String?
  ) -> ClassError {
    switch code {
    case "CLASS_409_RESULT_EXPIRED": return .resultExpired
    case "CLASS_403_MEMBER", "CLASS_403_OWNER": return .accessDenied
    default: return .network(message ?? "클래스 결과를 불러오지 못했어요.")
    }
  }

  static func feedbackError(code: String?) -> ClassAIFeedbackError {
    switch code {
    case "CLASS_409_REPORT_RETRY": return .generationFailed
    case "CLASS_409_RESULT_EXPIRED": return .resultExpired
    case "CLASS_403_MEMBER", "CLASS_403_OWNER": return .accessDenied
    default: return .temporarilyUnavailable
    }
  }

  static func feedbackError(_ error: Error) -> ClassAIFeedbackError {
    if let mapped = error as? ClassAIFeedbackError { return mapped }
    if error is DecodingError { return .invalidResponse }
    if let networkError = error as? PickeNetworkError {
      switch networkError {
      case .decoding: return .invalidResponse
      case let .response(response): return feedbackError(code: response.code)
      default: break
      }
    }
    return .temporarilyUnavailable
  }
}
