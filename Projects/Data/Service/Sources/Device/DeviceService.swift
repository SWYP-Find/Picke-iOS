//
//  DeviceService.swift
//  Service
//
//  FCM 디바이스 토큰 등록/해제 — POST/DELETE /api/v1/devices.
//  - register: JSON 바디 (fcmToken, platform)
//  - unregister: 쿼리 파라미터 (fcmToken)
//

import Foundation

import API
import NetworkHeader

import AsyncMoya

public enum DeviceService {
  /// POST /api/v1/devices
  case register(body: DeviceRegisterRequest)
  /// DELETE /api/v1/devices?fcmToken=...
  case unregister(fcmToken: String)
}

extension DeviceService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .device }

  public var urlPath: String { "" }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .register:
      return .post
    case .unregister:
      return .delete
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .register(body):
      return body.toDictionary
    case let .unregister(fcmToken):
      return ["fcmToken": fcmToken]
    }
  }

  /// unregister 는 쿼리 파라미터, register 는 JSON 바디로 인코딩.
  public var task: Moya.Task {
    switch self {
    case let .register(body):
      return .requestParameters(
        parameters: body.toDictionary ?? [:],
        encoding: JSONEncoding.default
      )
    case let .unregister(fcmToken):
      return .requestParameters(
        parameters: ["fcmToken": fcmToken],
        encoding: URLEncoding.queryString
      )
    }
  }

  public var headers: [String: String]? {
    APIHeader.baseHeader
  }
}
