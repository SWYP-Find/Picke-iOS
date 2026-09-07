//
//  NetworkClientDependency.swift
//  PickeNetworkInterface
//
//  네트워크 클라이언트의 DependencyKey.
//
//  실제 인증 클라이언트는 ServiceAssembly 가 `DependencyValues` 에 등록한다.
//  Interface 모듈에는 계약과 테스트 기본값만 둔다.
//

import Foundation

import Dependencies

public enum NetworkClientDependency: TestDependencyKey {
  public static var testValue: any PickeNetworkClient {
    UnimplementedNetworkClient()
  }
}

public extension DependencyValues {
  var networkClient: any PickeNetworkClient {
    get { self[NetworkClientDependency.self] }
    set { self[NetworkClientDependency.self] = newValue }
  }
}

/// 테스트에서 클라이언트를 갈아끼우지 않은 채 네트워크를 타면 알려주는 기본값.
/// 조용히 빈 응답을 돌려주면 테스트가 통과해버려 누락을 놓친다.
public struct UnimplementedNetworkClient: PickeNetworkClient {
  public init() {}

  public func send<R: PickeDataRequest, T: Decodable & Sendable>(
    _: R,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    reportUnimplemented()
  }

  public func send<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    reportUnimplemented()
  }

  public func sendResponse<R: PickeDataRequest>(_: R) async throws(PickeNetworkError) -> PickeHTTPResponse {
    reportUnimplemented()
  }

  public func upload<R: PickeUploadRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    reportUnimplemented()
  }

  public func upload(_: some PickeFileUploadRequest) async throws(PickeNetworkError) {
    reportUnimplemented()
  }

  private func reportUnimplemented() -> Never {
    fatalError(
      "networkClient 가 등록되지 않았다. 테스트라면 withDependencies 로 스텁을 넣고, "
        + "앱이라면 ServiceAssembly 의 liveValue 등록을 확인할 것."
    )
  }
}
