//
//  AppDeeplinkBridge.swift
//  Picke
//

import Foundation

import PickeCoreLogger
import PickeCoreUtility

enum AppDeeplinkBridge {
  private static var pendingStore: PendingDeeplinkStore { PendingDeeplinkStore() }

  /// 푸시 payload(userInfo) 를 딥링크로 변환 → 최신 대기 요청 저장 + 브로드캐스트.
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

  /// 딥링크를 최신 대기 요청에 저장하고 즉시 알림.
  static func broadcast(_ deeplink: PickeDeeplink) {
    pendingStore.save(deeplink)
    NotificationCenter.default.post(
      name: .pickeDeeplink,
      object: nil
    )
    PickeLogger.debug("[Deeplink] 브로드캐스트: \(deeplink.encoded)", category: .navigation)
  }

  static func consumePending() -> PickeDeeplink? {
    return pendingStore.consume()
  }
}
