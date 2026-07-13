//
//  PickeTargetType.swift
//  NetworkHeader
//
//  라이브러리 비의존 요청 스펙. AsyncMoya `BaseTargetType`(Moya `TargetType` 확장)을 대체해
//  Moya 없이 Alamofire 로 직접 요청을 만든다. Service 는 이 프로토콜만 conform 하면 되고,
//  실행 backend(Alamofire)는 NetworkProviding 구현이 담당한다.
//
//  호출부(Repository)는 여전히 `provider.request(target)` (AsyncMoya 스타일) 그대로 사용한다.
//

import Foundation

@_exported import Alamofire

/// 엔드포인트의 도메인(base URL + 도메인 경로).
public protocol PickeDomainType {
  var baseURLString: String { get }
  var url: String { get }
}

/// feature Service 가 conform 하는 요청 스펙. Moya 비의존.
public protocol PickeTargetType {
  associatedtype Domain: PickeDomainType
  var domain: Domain { get }
  var urlPath: String { get }
  var method: HTTPMethod { get }
  var parameters: [String: Any]? { get }
  var headers: [String: String]? { get }
  /// 파라미터 인코딩. 기본은 method 기준(아래 default). 케이스별로 달라야 하는 Service 는 재정의한다.
  var parameterEncoding: ParameterEncoding { get }
}

public extension PickeTargetType {
  /// 기본 헤더(APIHeader.baseHeader). Service 가 재정의 가능.
  var headers: [String: String]? { APIHeader.baseHeader }

  /// 동작 보존: AsyncMoya BaseTargetType 은 GET 만 쿼리스트링, 그 외(POST/PATCH/DELETE)는 JSON 바디로
  /// 인코딩했다(예: AuthService.withdraw DELETE + token → JSON body). 그 규칙을 기본값으로 따른다.
  /// (DeviceService.unregister 처럼 DELETE 인데 쿼리스트링이 필요한 케이스는 이 프로퍼티를 재정의)
  var parameterEncoding: ParameterEncoding {
    (method == .get) ? URLEncoding.queryString : JSONEncoding.default
  }

  /// Alamofire 로 전송 가능한 `URLRequest` 생성. Moya `Endpoint` 를 대체.
  /// 인코딩 위치는 method 기준(GET/DELETE 쿼리스트링, 그 외 JSON 바디) — Joongna JNNetwork 와 동일.
  func asURLRequest() throws -> URLRequest {
    guard let base = URL(string: domain.baseURLString) else {
      throw PickeNetworkError.invalidBaseURL(domain.baseURLString)
    }
    let fullURL = base.appendingPathComponent(domain.url + urlPath)
    var request = try URLRequest(
      url: fullURL,
      method: method,
      headers: headers.map { HTTPHeaders($0) }
    )
    if let parameters {
      request = try parameterEncoding.encode(request, with: parameters)
    }
    return request
  }
}

public enum PickeNetworkError: Error {
  case invalidBaseURL(String)
  case emptyData
  case statusCode(Int, Data)
}
