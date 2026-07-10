//
//  PushDeeplinkBridge.swift
//  Picke
//
//  AppDelegate(푸시 탭) → TCA(AppReducer) 사이 딥링크 전달 브리지. (TimeSpot-iOS 패턴)
//  파싱한 딥링크를 NotificationCenter 로 브로드캐스트하고, 콜드 스타트 대비 UserDefaults 에도 보관.
//

import Foundation

import Domain
import LogMacro

enum PushDeeplinkBridge {
  static let pendingKey = "PickePendingDeeplink"

  /// 푸시 payload(userInfo) 를 딥링크로 변환 → 대기열 저장 + 브로드캐스트.
  static func handlePushPayload(_ userInfo: [AnyHashable: Any]) {
    guard let deeplink = PickeDeeplinkParser.parse(pushPayload: userInfo) else {
      #logDebug("[Deeplink] 처리 가능한 푸시 페이로드 없음")
      return
    }
    broadcast(deeplink)
  }

  /// 커스텀 스킴(picke://...) / 유니버설 링크 URL 로 앱이 열렸을 때.
  static func handleURL(_ url: URL) {
    guard let deeplink = PickeDeeplinkParser.parse(urlString: url.absoluteString) else {
      #logDebug("[Deeplink] 처리 불가 URL: \(url.absoluteString)")
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
    #logDebug("[Deeplink] 브로드캐스트: \(deeplink.encoded)")
  }

  /// AppReducer 가 라우팅을 끝낸 뒤 대기열 비움.
  static func consumePending() -> PickeDeeplink? {
    guard let encoded = UserDefaults.standard.string(forKey: pendingKey) else { return nil }
    UserDefaults.standard.removeObject(forKey: pendingKey)
    return PickeDeeplinkParser.parse(urlString: encoded)
  }
}
