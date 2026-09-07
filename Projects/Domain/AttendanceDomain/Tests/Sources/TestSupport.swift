//
//  TestSupport.swift
//  AttendanceDataTests
//

import Foundation

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

  func send<R: PickeDataRequest, T: Decodable & Sendable>(
    _: R,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    try decode(T.self)
  }

  func send<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    try decode(R.Response.self)
  }

  func sendResponse<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> PickeHTTPResponse {
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

  func send<R: PickeDataRequest, T: Decodable & Sendable>(
    _: R,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    throw .transport(.unknown(StubError()))
  }

  func send<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    throw .transport(.unknown(StubError()))
  }

  func sendResponse<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> PickeHTTPResponse {
    throw .transport(.unknown(StubError()))
  }

  func upload<R: PickeUploadRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    throw .transport(.unknown(StubError()))
  }

  func upload(_: some PickeFileUploadRequest) async throws(PickeNetworkError) {
    throw .transport(.unknown(StubError()))
  }
}
