//
//  DeviceTokenStorage.swift
//  PickeStorageInterface
//

import Sharing

/// APNs 디바이스 토큰 보관소. PickeStorage 영속 경계와 테스트 메모리 경계를 함께 사용한다.
public enum DeviceTokenStorage {
  public static var token: String? {
    get {
      @Shared(.deviceToken) var token: String?
      return token
    }
    set {
      @Shared(.deviceToken) var token: String?
      $token.withLock { $0 = newValue }
    }
  }
}
