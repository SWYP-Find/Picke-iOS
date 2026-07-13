//
//  NetworkProviding.swift
//  Repository
//
//  네트워크 요청 실행 추상화. Repository 는 구체 `MoyaProvider` 대신 이 프로토콜에 의존한다.
//  AsyncMoya→Alamofire 전환 시 이 프로토콜을 구현하는 provider 만 교체하면 되도록 하는 발판.
//

import Foundation

import Moya

/// feature Service(`TargetType`) 단위의 네트워크 요청 실행 추상.
public protocol NetworkProviding<Target> {
  associatedtype Target: TargetType

  /// 응답을 `Decodable` 로 디코딩해 반환.
  func request<D: Decodable & Sendable>(_ target: Target) async throws -> D

  /// 원시 Moya `Response` 반환(디코딩 전).
  func requestResponse(_ target: Target) async throws -> Response
}

/// 현 구현체. `request`(AsyncMoya)·`requestResponse`(로컬 확장)를 이미 갖고 있어 요구사항을 그대로 충족.
extension MoyaProvider: NetworkProviding {}
