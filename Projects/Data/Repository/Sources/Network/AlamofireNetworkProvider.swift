//
//  AlamofireNetworkProvider.swift
//  Repository
//
//  NetworkProviding 의 Alamofire 구현체. AsyncMoya→Alamofire 전환의 실제 백엔드.
//  호출부(Repository)는 기존 `provider.request(target)` (AsyncMoya 스타일) 그대로 사용한다.
//
//  동작 보존: Moya 도 내부적으로 Alamofire `Session` 을 쓰므로, 여기서도 `OptimizedSessionManager`
//  의 동일 Session(인터셉터·토큰 갱신·이벤트 모니터 포함)을 재사용해 인증/리트라이 동작을 그대로 유지한다.
//  엔드포인트는 기존 Moya `TargetType`(=각 feature Service) 을 그대로 받아 URLRequest 로 매핑하므로,
//  Service 정의도 바꿀 필요가 없다.
//

import Foundation

import Alamofire
import Moya

/// `NetworkProviding` 의 Alamofire 백엔드. 기본값(`.authorized`)을 이 provider 로 바꾸면
/// 라이브러리 전환이 완료된다.
public struct AlamofireNetworkProvider<Target: TargetType>: NetworkProviding {
  private let session: Session
  private let decoder: JSONDecoder

  /// - Parameter session: 기본(nil)은 Moya 가 쓰는 것과 동일한 인증 세션(동작 보존).
  public init(
    session: Session? = nil,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.session = session ?? OptimizedSessionManager.shared.session
    self.decoder = decoder
  }

  /// Moya `TargetType` → `URLRequest`. Moya `Endpoint` 의 인코딩 로직을 재사용해 task/헤더를 그대로 반영.
  private func urlRequest(for target: Target) throws -> URLRequest {
    let endpoint = Endpoint(
      url: URL(target: target).absoluteString,
      sampleResponseClosure: { .networkResponse(200, target.sampleData) },
      method: target.method,
      task: target.task,
      httpHeaderFields: target.headers
    )
    return try endpoint.urlRequest()
  }

  public func request<D: Decodable & Sendable>(_ target: Target) async throws -> D {
    let request = try urlRequest(for: target)
    return try await session
      .request(request)
      .validate()
      .serializingDecodable(D.self, decoder: decoder)
      .value
  }

  public func requestResponse(_ target: Target) async throws -> Response {
    let request = try urlRequest(for: target)
    let dataTask = session.request(request).serializingData()
    let response = await dataTask.response
    let data = try response.result.get()
    return Response(
      statusCode: response.response?.statusCode ?? 0,
      data: data,
      request: response.request,
      response: response.response
    )
  }
}
