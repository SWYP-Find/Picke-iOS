//
//  DefaultHeaders.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

/// 모든 요청에 공통으로 박히는 정적 헤더.
/// 요청별 헤더는 `PickeEndpoint.headers`, 토큰은 `PickeAuthenticator` 가 붙인다.
/// Content-Type 은 인코더 / 멀티파트가 요청마다 정하므로 여기서 고정하지 않는다.
enum DefaultHeaders {
  static var headers: HTTPHeaders {
    var headers = HTTPHeaders.default
    headers.add(name: "Accept", value: APIHeaderManger.contentType)
    return headers
  }
}
