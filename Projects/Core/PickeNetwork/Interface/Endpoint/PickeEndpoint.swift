//
//  PickeEndpoint.swift
//  PickeNetworkInterface
//

import Foundation

import Alamofire

/// 엔드포인트가 속한 도메인. base URL 과 도메인 경로 접두사를 묶는다.
public protocol PickeDomainType: Sendable {
  var baseURLString: String { get }
  var url: String { get }
}

/// 일반 요청(`PickeDataRequest`)·멀티파트 업로드(`PickeUploadRequest`)가 공유하는 엔드포인트 메타.
public protocol PickeEndpoint {
  /// 엔드포인트가 속한 도메인 (base URL + 경로 접두사)
  var domain: any PickeDomainType { get }
  /// 도메인 경로 뒤에 붙는 경로 (예: "3/participation")
  var path: String { get }
  /// HTTP 메서드
  var method: HTTPMethod { get }
  /// 요청 헤더 (공통 헤더는 세션이 붙인다 — 여기엔 이 요청만의 헤더를 둔다)
  var headers: HTTPHeaders { get }
  /// 타임아웃(초). nil 이면 세션 기본값 사용.
  var timeoutInterval: TimeInterval? { get }
  /// 최대 재시도 횟수 (0 = 재시도 안 함)
  var maxRetryAttempts: Int { get }
  /// 인증 정책. 기본값 `.automatic` — 예외 엔드포인트만 선언한다.
  var authorization: PickeAuthorization { get }
}

public extension PickeEndpoint {
  var headers: HTTPHeaders {
    [:]
  }

  var timeoutInterval: TimeInterval? {
    nil
  }

  /// 기본 재시도 횟수.
  var maxRetryAttempts: Int {
    3
  }

  /// 기본 인증 정책 — 로그인 상태면 토큰 부착.
  var authorization: PickeAuthorization {
    .automatic
  }

  /// `baseURLString + domain.url + path` 로 조합한 최종 URL.
  func url() throws(PickeNetworkError) -> URL {
    guard let base = URL(string: domain.baseURLString) else {
      throw .request(.invalidURL)
    }
    return base.appendingPathComponent(domain.url + path)
  }
}
