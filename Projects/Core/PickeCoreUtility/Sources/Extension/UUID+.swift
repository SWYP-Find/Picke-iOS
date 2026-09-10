//
//  UUID+Deterministic.swift
//  PickeCoreUtility
//

import Foundation

public extension UUID {
  /// 두 정수로부터 결정적(deterministic) UUID 생성. 같은 입력 → 항상 같은 UUID.
  /// 마지막 12 hex 를 `high`(8) + `low`(4) 로 채운다.
  static func deterministic(_ high: Int, _ low: Int = 0) -> UUID {
    let hex = String(format: "%08X%04X", high & 0xFFFF_FFFF, low & 0xFFFF)
    return UUID(uuidString: "00000000-0000-0000-0000-\(hex)") ?? UUID()
  }
}
