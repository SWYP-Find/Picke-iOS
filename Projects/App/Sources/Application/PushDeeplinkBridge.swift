//
//  PushDeeplinkBridge.swift
//  Picke
//

import Foundation

import DomainAssembly
import PickeCoreLogger
import PickeCoreUtility

enum PushDeeplinkBridge {
  static let pendingKey = "PickePendingDeeplink"

  /// 푸시 payload(userInfo) 를 딥링크로 변환 → 대기열 저장 + 브로드캐스트.
  static func handlePushPayload(_ userInfo: [AnyHashable: Any]) {
    guard let deeplink = PickeDeeplinkParser.parse(pushPayload: userInfo) else {
      PickeLogger.debug("[Deeplink] 처리 가능한 푸시 페이로드 없음", category: .navigation)
      return
    }
    broadcast(deeplink)
  }

  /// 커스텀 스킴(picke://...) / 유니버설 링크 URL 로 앱이 열렸을 때.
  static func handleURL(_ url: URL) {
    guard let deeplink = PickeDeeplinkParser.parse(urlString: url.absoluteString) else {
      PickeLogger.debug("[Deeplink] 처리 불가 URL: \(url.absoluteString)", category: .navigation)
      return
    }
    broadcast(deeplink)
  }

  /// 딥링크를 대기열에 저장하고 즉시 알림.
  static func broadcast(_ deeplink: PickeDeeplink) {
    UserDefaults.standard.set(deeplink.encoded, forKey: pendingKey)
    NotificationCenter.default.post(
      name: .pickeDeeplink,
      object: nil,
      userInfo: ["deeplink": deeplink.encoded]
    )
    PickeLogger.debug("[Deeplink] 브로드캐스트: \(deeplink.encoded)", category: .navigation)
  }

  /// AppReducer 가 라우팅을 끝낸 뒤 대기열 비움.
  static func consumePending() -> PickeDeeplink? {
    guard let encoded = UserDefaults.standard.string(forKey: pendingKey) else { return nil }
    UserDefaults.standard.removeObject(forKey: pendingKey)
    return PickeDeeplinkParser.parse(urlString: encoded)
  }
}
