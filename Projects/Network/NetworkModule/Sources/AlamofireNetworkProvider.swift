//
//  AlamofireNetworkProvider.swift
//  NetworkModule
//

import Foundation

import Alamofire
import NetworkHeader

/// `NetworkProviding` 의 Alamofire 백엔드.
/// - `.authorized`: 인증 인터셉터가 얹힌 세션(대부분의 요청).
/// - `.default`: 인증 없는 세션(로그인/토큰 재발급 등 토큰이 아직 없는 요청).
public struct AlamofireNetworkProvider<Target: PickeTargetType>: NetworkProviding {
  private let session: Session
  private let decoder: JSONDecoder

  /// - Parameter session: 기본(nil)은 인증 세션(동작 보존).
  public init(
    session: Session? = nil,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.session = session ?? OptimizedSessionManager.shared.session
    self.decoder = decoder
  }

  public func request<D: Decodable & Sendable>(_ target: Target) async throws -> D {
    let request = try target.asURLRequest()
    return try await session
      .request(request)
      .validate()
      .serializingDecodable(D.self, decoder: decoder)
      .value
  }

  public func requestResponse(_ target: Target) async throws -> PickeResponse {
    let request = try target.asURLRequest()
    let dataTask = session.request(request).serializingData()
    let response = await dataTask.response
    let data = try response.result.get()
    return PickeResponse(
      statusCode: response.response?.statusCode ?? 0,
      data: data
    )
  }
}

public extension AlamofireNetworkProvider {
  /// 인증 세션(인터셉터 부착) 기반 provider. 기존 `MoyaProvider.authorized` 대체.
  static var authorized: AlamofireNetworkProvider {
    AlamofireNetworkProvider(session: OptimizedSessionManager.shared.session)
  }

  /// 인증 없는 세션 기반 provider. 기존 `MoyaProvider.default` 대체.
  static var `default`: AlamofireNetworkProvider {
    AlamofireNetworkProvider(session: OptimizedSessionManager.shared.plainSession)
  }
}
