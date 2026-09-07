//
//  NetworkClient.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

/// Alamofire 기반 `PickeNetworkClient` 구현.
///
/// 서버는 성공/실패를 HTTP status 로 알리고, 바디는 공통 봉투(`{ statusCode, data, error }`)에 담아 준다.
/// 봉투 해석은 이 클라이언트가 전담한다 — 호출부는 페이로드 DTO 만 받고, `error` 는 `ResponseError` 로 받는다.
final class NetworkClient: PickeNetworkClient {
  /// 바디가 비어도 성공으로 볼 status. (201 Created / 202 Accepted / 204 No Content 등)
  private static let emptyResponseCodes: Set<Int> = [200, 201, 202, 204, 205]

  /// 조립된 Alamofire 세션
  private let session: Session
  /// 요청별 인증 조립용 공유 인터셉터. nil 이면 인증 파이프라인 없는 클라이언트(plain).
  private let authorizing: AuthorizingInterceptor?

  init(
    session: Session,
    authorizing: AuthorizingInterceptor? = nil
  ) {
    self.session = session
    self.authorizing = authorizing
  }
}

// MARK: - PickeRequestClient (일반 요청)

extension NetworkClient: PickeRequestClient {
  func send<R: PickeDataRequest, T: Decodable & Sendable>(
    _ request: R,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    let dataRequest = try makeDataRequest(request)
    return try await handle(dataRequest, as: T.self)
  }

  func send<R: PickeDataRequest>(_ request: R) async throws(PickeNetworkError) -> R.Response {
    let dataRequest = try makeDataRequest(request)
    return try await handle(dataRequest, as: R.Response.self)
  }

  func sendResponse<R: PickeDataRequest>(_ request: R) async throws(PickeNetworkError) -> PickeHTTPResponse {
    let dataRequest = try makeDataRequest(request)
    let startedAt = Date()
    let response = await dataRequest.serializingData(emptyResponseCodes: Self.emptyResponseCodes).response
    Self.recordTelemetry(response: response.response, request: response.request, startedAt: startedAt, isSuccess: response.error == nil)
    if let error = response.error, response.response == nil {
      throw Self.mapFailure(error, data: response.data, status: -1)
    }
    return PickeHTTPResponse(
      statusCode: response.response?.statusCode ?? -1,
      data: response.data ?? Data()
    )
  }

  /// 요청을 URLRequest 로 만들고 인증·재시도 인터셉터를 조립한다. 두 send 오버로드가 공유한다.
  private func makeDataRequest<R: PickeDataRequest>(_ request: R) throws(PickeNetworkError) -> DataRequest {
    // 1) PickeDataRequest → URLRequest (헤더 / 타임아웃 / 파라미터 인코딩)
    let urlRequest: URLRequest
    do {
      urlRequest = try request.asURLRequest()
    } catch let error as PickeNetworkError {
      throw error
    } catch {
      throw .request(.encodingFailed(error))
    }

    // 2) 인증(요청의 authorization 정책)과 재시도를 요청별로 조립한다.
    return session.request(urlRequest, interceptor: interceptor(for: request))
  }
}

// MARK: - PickeUploadClient (멀티파트 업로드)

extension NetworkClient: PickeUploadClient {
  func upload<R: PickeUploadRequest>(_ request: R) async throws(PickeNetworkError) -> R.Response {
    let url = try request.url()
    // escaping 클로저에는 Sendable 값만 캡처한다.
    let parts = request.parts
    let timeout = request.timeoutInterval

    // UploadRequest 는 DataRequest 의 하위 → 응답 처리(handle)를 그대로 공유한다.
    let uploadRequest = session.upload(
      multipartFormData: { form in parts.forEach { Self.append($0, to: form) } },
      to: url,
      method: request.method,
      headers: request.headers,
      interceptor: interceptor(for: request),
      requestModifier: { urlRequest in
        if let timeout { urlRequest.timeoutInterval = timeout }
      }
    )
    return try await handle(uploadRequest, as: R.Response.self)
  }
}

// MARK: - PickeFileUploadClient (presigned 원본 바이트 PUT)

extension NetworkClient: PickeFileUploadClient {
  func upload(_ request: some PickeFileUploadRequest) async throws(PickeNetworkError) {
    var urlRequest = URLRequest(url: request.uploadURL)
    urlRequest.method = .put
    urlRequest.httpBody = request.body
    urlRequest.setValue(request.contentType, forHTTPHeaderField: APIHeader.contentType)
    if let timeout = request.timeoutInterval {
      urlRequest.timeoutInterval = timeout
    }

    let response = await session.request(urlRequest, interceptor: request.retryPolicy)
      .validate()
      .serializingData(emptyResponseCodes: Self.emptyResponseCodes)
      .response

    if case let .failure(afError) = response.result {
      throw Self.mapFailure(afError, data: response.data, status: response.response?.statusCode ?? -1)
    }
  }
}

// MARK: - 요청별 인터셉터

private extension NetworkClient {
  /// 요청의 인증 정책에 따라 인터셉터를 조립한다.
  func interceptor(for request: some PickeEndpoint) -> any RequestInterceptor {
    guard let authorizing, request.authorization == .automatic else {
      return request.retryPolicy
    }
    return Interceptor(interceptors: [authorizing, request.retryPolicy])
  }
}

// MARK: - Response Handling (send / upload 공유)

private extension NetworkClient {
  /// 응답을 `T` 로 디코딩한다. 실패 판정은 `validate()` 의 HTTP status 검증이 맡고,
  /// 실패 바디에 담긴 `{ code, message }` 는 `ResponseError` 로 살려 낸다.
  func handle<T: Decodable & Sendable>(
    _ dataRequest: DataRequest,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    let startedAt = Date()
    let response = await dataRequest
      .validate()
      .serializingDecodable(
        ResponseEnvelope<T>.self,
        emptyResponseCodes: Self.emptyResponseCodes
      )
      .response
    Self.recordTelemetry(
      response: response.response,
      request: response.request,
      startedAt: startedAt,
      isSuccess: response.error == nil
    )

    switch response.result {
    case let .success(envelope):
      return try Self.unwrap(envelope, status: response.response?.statusCode ?? -1)
    case let .failure(afError):
      throw Self.mapFailure(afError, data: response.data, status: response.response?.statusCode ?? -1)
    }
  }

  /// 봉투의 `error` 를 에러로 승격시키고, 없으면 페이로드를 꺼낸다.
  /// HTTP 2xx 여도 `error` 가 채워져 있으면 실패로 본다 — 서버가 200 에 실패를 담아 보내는 경로가 있다.
  static func unwrap<T: Decodable & Sendable>(
    _ envelope: ResponseEnvelope<T>,
    status: Int
  ) throws(PickeNetworkError) -> T {
    if let failure = envelope.error {
      throw .response(
        ResponseError(
          httpStatus: envelope.statusCode ?? status,
          code: failure.code,
          message: failure.message
        )
      )
    }
    guard let data = envelope.data else {
      // 페이로드를 기대하지 않는 요청(`PickeEmptyResponse`)은 빈 바디도 성공이다.
      guard let empty = PickeEmptyResponse() as? T else {
        throw .decoding(.dataMissing)
      }
      return empty
    }
    return data
  }

  static func recordTelemetry(
    response: HTTPURLResponse?,
    request: URLRequest?,
    startedAt: Date,
    isSuccess: Bool
  ) {
    NetworkTelemetry.shared.record(
      NetworkTelemetryEvent(
        source: "alamofire",
        method: request?.httpMethod ?? "UNKNOWN",
        url: request?.url,
        statusCode: response?.statusCode,
        duration: Date().timeIntervalSince(startedAt),
        isSuccess: isSuccess
      )
    )
  }
}

// MARK: - Multipart 매핑

private extension NetworkClient {
  /// `PickeMultipartPart` → Alamofire `MultipartFormData` 한 파트 추가.
  static func append(_ part: PickeMultipartPart, to form: MultipartFormData) {
    switch part.source {
    case let .data(data):
      form.append(data, withName: part.name, fileName: part.fileName, mimeType: part.mimeType)
    case let .file(url):
      if let fileName = part.fileName, let mimeType = part.mimeType {
        form.append(url, withName: part.name, fileName: fileName, mimeType: mimeType)
      } else {
        form.append(url, withName: part.name)
      }
    }
  }
}

// MARK: - Error 매핑

private extension NetworkClient {
  /// `AFError` 를 파이프라인 단계별 `PickeNetworkError` 로 좁힌다.
  static func mapFailure(_ error: AFError, data: Data?, status: Int) -> PickeNetworkError {
    switch error {
    // 상태코드 검증 실패 — 서버가 내려준 에러. 바디의 code/message 를 살린다.
    case .responseValidationFailed(.unacceptableStatusCode):
      let body = data.flatMap { try? JSONDecoder().decode(ErrorBody.self, from: $0) }
      return .response(
        ResponseError(httpStatus: status, code: body?.resolvedCode, message: body?.resolvedMessage)
      )

    // 응답 디코딩 실패 — PickeEventMonitor 가 원시 바디와 함께 로깅한다.
    case let .responseSerializationFailed(.decodingFailed(decodingError)):
      return .decoding(.failed(decodingError))

    // 값을 기대했는데 바디가 비어 있음
    case .responseSerializationFailed(.inputDataNilOrZeroLength),
         .responseSerializationFailed(.invalidEmptyResponse):
      return .decoding(.dataMissing)

    // 서버가 JSON 아닌 응답을 줌 (콘텐츠 타입 불일치)
    case .responseValidationFailed(.unacceptableContentType),
         .responseValidationFailed(.missingContentType):
      return .decoding(.failed(error))

    // 전송 실패(오프라인 / 타임아웃 / 취소) 및 그 외(요청 적응·재시도 실패, TLS 등)
    default:
      return .transport(mapTransportError(error))
    }
  }

  /// `AFError` → `TransportError` (연결 없음 / 타임아웃 / 취소 / 기타).
  static func mapTransportError(_ error: AFError) -> TransportError {
    if case .explicitlyCancelled = error {
      return .cancelled
    }
    guard let urlError = error.underlyingError as? URLError else {
      return .unknown(error)
    }
    switch urlError.code {
    case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost:
      return .notConnected
    case .timedOut:
      return .timedOut
    case .cancelled:
      return .cancelled
    default:
      return .unknown(error)
    }
  }
}
