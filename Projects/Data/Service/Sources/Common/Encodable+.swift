//
//  Encodable+.swift
//  Service
//
//  Created by Wonji Suh  on 3/12/26.
//

import Foundation

public extension Encodable {
  /// `Encodable` 을 API 파라미터용 `[String: Any]` 로 변환.
  /// JSON 표준은 `/` 의 이스케이프를 허용하지만 로그 가독성을 위해 비활성.
  var toDictionary: [String: Any]? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    guard let data = try? encoder.encode(self) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  }
}

extension String {
  /// 문자열을 지정된 키로 API 파라미터용 Dictionary 로 변환
  func toDictionary(key: String) -> [String: Any] {
    [key: self]
  }
}

extension Int {
  func toDictionary(key: String) -> [String: Any] {
    [key: self]
  }
}
