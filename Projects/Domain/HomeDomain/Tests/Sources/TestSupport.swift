//
//  TestSupport.swift
//  HomeDataTests
//

import Foundation
import Testing

import PickeNetwork

/// 고정 데이터를 서버 응답 봉투(`{ statusCode, data, error }`)로 해석해 돌려주는 스텁 클라이언트.
/// 실클라이언트와 같은 규칙으로 `error` 를 `ResponseError` 로 승격시킨다.
struct StubNetworkClient: PickeNetworkClient {
  private struct Envelope<Payload: Decodable>: Decodable {
    struct Failure: Decodable {
      let code: String?
      let message: String?
    }

    let statusCode: Int?
    let data: Payload?
    let error: Failure?
  }

  let stubData: Data
  var statusCode: Int = 200

  func send<T: Decodable & Sendable>(
    _: some PickeDataRequest,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    try decode(T.self)
  }

  func send<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    try decode(R.Response.self)
  }

  func sendResponse(_: some PickeDataRequest) async throws(PickeNetworkError) -> PickeHTTPResponse {
    PickeHTTPResponse(statusCode: statusCode, data: stubData)
  }

  func upload<R: PickeUploadRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    try decode(R.Response.self)
  }

  func upload(_: some PickeFileUploadRequest) async throws(PickeNetworkError) {}

  private func decode<T: Decodable>(_: T.Type) throws(PickeNetworkError) -> T {
    let envelope: Envelope<T>
    do {
      envelope = try JSONDecoder().decode(Envelope<T>.self, from: stubData)
    } catch {
      throw .decoding(.failed(error))
    }
    if let failure = envelope.error {
      throw .response(
        ResponseError(
          httpStatus: envelope.statusCode ?? statusCode,
          code: failure.code,
          message: failure.message
        )
      )
    }
    guard let data = envelope.data else {
      guard let empty = PickeEmptyResponse() as? T else {
        throw .decoding(.dataMissing)
      }
      return empty
    }
    return data
  }
}

/// 항상 에러를 던지는 스텁 클라이언트.
struct ThrowingStubNetworkClient: PickeNetworkClient {
  struct StubError: Error {}

  func send<T: Decodable & Sendable>(
    _: some PickeDataRequest,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    throw .transport(.unknown(StubError()))
  }

  func send<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    throw .transport(.unknown(StubError()))
  }

  func sendResponse(_: some PickeDataRequest) async throws(PickeNetworkError) -> PickeHTTPResponse {
    throw .transport(.unknown(StubError()))
  }

  func upload<R: PickeUploadRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    throw .transport(.unknown(StubError()))
  }

  func upload(_: some PickeFileUploadRequest) async throws(PickeNetworkError) {
    throw .transport(.unknown(StubError()))
  }
}

func expectNetworkResponseError(
  statusCode: Int? = nil,
  code: String? = nil,
  message: String?,
  operation: () async throws -> Void
) async {
  do {
    try await operation()
    Issue.record("네트워크 응답 에러가 던져져야 합니다")
  } catch let error as PickeNetworkError {
    guard case let .response(response) = error else {
      Issue.record("response 에러여야 합니다: \(error)")
      return
    }
    if let statusCode {
      #expect(response.httpStatus == statusCode)
    }
    if let code {
      #expect(response.code == code)
    }
    #expect(response.message == message)
  } catch {
    Issue.record("예상치 못한 에러 타입: \(error)")
  }
}
