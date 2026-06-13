//
//  InfoPlistDictionary.swift
//  Plugins
//
//  Created by Wonji Suh  on 3/22/25.
//

import Foundation
import ProjectDescription

public typealias InfoPlistDictionary = [String: Plist.Value]

extension InfoPlistDictionary {
  func setUIUserInterfaceStyle(_ value: String) -> InfoPlistDictionary {
    merging(["UIUserInterfaceStyle": .string(value)]) { _, new in new }
  }

  func setCFBundleDevelopmentRegion(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleDevelopmentRegion": .string(value)]) { _, new in new }
  }

  func setCFBundleExecutable(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleExecutable": .string(value)]) { _, new in new }
  }

  func setCFBundleIdentifier(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleIdentifier": .string(value)]) { _, new in new }
  }

  func setCFBundleInfoDictionaryVersion(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleInfoDictionaryVersion": .string(value)]) { _, new in new }
  }

  func setCFBundleName(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleName": .string(value)]) { _, new in new }
  }

  func setCFBundleDisplayName(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleDisplayName": .string(value)]) { _, new in new }
  }

  func setCFBundlePackageType(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundlePackageType": .string(value)]) { _, new in new }
  }

  func setCFBundleShortVersionString(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleShortVersionString": .string(value)]) { _, new in new }
  }

  // 매개변수 없는 경우, 기본 지역을 "ko"로 설정
  func setCFBundleDevelopmentRegion() -> InfoPlistDictionary {
    merging(["CFBundleDevelopmentRegion": .string("ko")]) {
      _, new in new
    }
  }

  func setCFBundleURLTypes(_ value: [[String: Any]]) -> InfoPlistDictionary {
    func convertToPlistValue(_ value: Any) -> Plist.Value {
      switch value {
      case let string as String:
        .string(string)
      case let array as [Any]:
        .array(array.map { convertToPlistValue($0) })
      case let dictionary as [String: Any]:
        .dictionary(dictionary.mapValues { convertToPlistValue($0) })
      case let bool as Bool:
        .boolean(bool)
      default:
        .string("\(value)")
      }
    }
    let dict: [String: Plist.Value] = [
      "CFBundleURLTypes": .array(value.map { .dictionary($0.mapValues { convertToPlistValue($0) }) }),
    ]
    return merging(dict) { _, new in new }
  }

  func setCFBundleVersion(_ value: String) -> InfoPlistDictionary {
    merging(["CFBundleVersion": .string(value)]) { _, new in new }
  }

  func setGIDClientID(_ value: String) -> InfoPlistDictionary {
    merging(["GIDClientID": .string(value)]) { _, new in new }
  }

  func setLSRequiresIPhoneOS(_ value: Bool) -> InfoPlistDictionary {
    merging(["LSRequiresIPhoneOS": .boolean(value)]) { _, new in new }
  }

  func setUIAppFonts(_ value: [String]) -> InfoPlistDictionary {
    merging(["UIAppFonts": .array(value.map { .string($0) })]) { _, new in new }
  }

  func setAppTransportSecurity() -> InfoPlistDictionary {
    let dict: [String: Plist.Value] = [
      "NSAppTransportSecurity": .dictionary([
        "NSAllowsArbitraryLoads": .boolean(true),
      ]),
    ]
    return merging(dict) { _, new in new }
  }

  // URL 타입 (picke 커스텀 스킴 + Google REVERSED_CLIENT_ID)
  func setCFBundleURLTypes() -> InfoPlistDictionary {
    let dict: [String: Plist.Value] = [
      "CFBundleURLTypes": .array([
        .dictionary([
          "CFBundleURLName": .string("picke"),
          "CFBundleURLSchemes": .array([
            .string("picke"),
          ]),
        ]),
        .dictionary([
          "CFBundleURLName": .string("google-oauth"),
          "CFBundleURLSchemes": .array([
            .string("${REVERSED_CLIENT_ID}"),
          ]),
        ]),
      ]),
    ]
    return merging(dict) { _, new in new }
  }

  func setLSApplicationQueriesSchemes(_ value: [String]) -> InfoPlistDictionary {
    merging([
      "LSApplicationQueriesSchemes": .array(value.map { .string($0) }),
    ]) { _, new in new }
  }

  func setKakaoRestApiKey(_ value: String = "$(KAKAO_REST_API_KEY)") -> InfoPlistDictionary {
    merging(["KAKAO_REST_API_KEY": .string(value)]) { _, new in new }
  }

  func setUIApplicationSceneManifest(_ value: [String: Any]) -> InfoPlistDictionary {
    func convertToPlistValue(_ value: Any) -> Plist.Value {
      switch value {
      case let string as String:
        .string(string)
      case let array as [Any]:
        .array(array.map { convertToPlistValue($0) })
      case let dictionary as [String: Any]:
        .dictionary(dictionary.mapValues { convertToPlistValue($0) })
      case let bool as Bool:
        .boolean(bool)
      default:
        .string("\(value)")
      }
    }
    let dict: [String: Plist.Value] = [
      "UIApplicationSceneManifest": convertToPlistValue(value),
    ]
    return merging(dict) { _, new in new }
  }

  func setUILaunchStoryboardName(_ value: String) -> InfoPlistDictionary {
    merging(["UILaunchStoryboardName": .string(value)]) { _, new in new }
  }

  func setUIRequiredDeviceCapabilities(_ value: [String]) -> InfoPlistDictionary {
    merging(["UIRequiredDeviceCapabilities": .array(value.map { .string($0) })]) { _, new in new }
  }

  func setUISupportedInterfaceOrientations(_ value: [String]) -> InfoPlistDictionary {
    merging(["UISupportedInterfaceOrientations": .array(value.map { .string($0) })]) { _, new in new }
  }

  func setNSCameraUsageDescription(_ value: String) -> InfoPlistDictionary {
    merging(["NSCameraUsageDescription": .string(value)]) { _, new in new }
  }

  func setUILaunchScreens() -> InfoPlistDictionary {
    let dict: InfoPlistDictionary = [
      "UILaunchScreen": .dictionary([
        "UIColorName": .string(""),
        "UIImageName": .string(""),
      ]),
    ]
    return merging(dict) { _, new in new }
  }

  func setAppUseExemptEncryption(value: Bool) -> InfoPlistDictionary {
    merging(["ITSAppUsesNonExemptEncryption": .boolean(value)]) { _, new in new }
  }

  func setFirebaseAnalyticsCollectionEnabled() -> InfoPlistDictionary {
    merging(["FIREBASE_ANALYTICS_COLLECTION_ENABLED": .boolean(false)]) { _, new in new }
  }

  func setCalenderUsage(_ description: String) -> InfoPlistDictionary {
    merging(["NSCalendarsUsageDescription": .string(description)]) { _, new in new }
  }

  func setGoogleReversedClientID(_ value: String) -> InfoPlistDictionary {
    merging(["REVERSED_CLIENT_ID": .string(value)]) { _, new in new }
  }

  func setGoogleClientID(_ value: String) -> InfoPlistDictionary {
    merging(["GOOGLE_CLIENT_ID": .string(value)]) { _, new in new }
  }

  func setGoogleClientiOSID(_ value: String) -> InfoPlistDictionary {
    merging(["GOOGLE_IOS_CLIENT_ID": .string(value)]) { _, new in new }
  }

  func setMixpanelToken(_ value: String) -> InfoPlistDictionary {
    merging(["MIXPANEL_TOKEN": .string(value)]) { _, new in new }
  }

  func setBaseURL(_ value: String) -> InfoPlistDictionary {
    merging(["BASE_URL": .string(value)]) { _, new in new }
  }

  func setAdmobToken(_ value: String) -> InfoPlistDictionary {
    merging(["ADMOB_TOKEN": .string(value)]) { _, new in new }
  }

  func setGADApplicationId(_ value: String) -> InfoPlistDictionary {
    merging(["GADApplicationIdentifier": .string(value)]) { _, new in new }
  }

  func setRewardAdUnit(_ value: String) -> InfoPlistDictionary {
    merging(["REWARD_AD_UNIT": .string(value)]) { _, new in new }
  }

  func setSKAdNetworkItems(_ identifiers: [String]) -> InfoPlistDictionary {
    merging([
      "SKAdNetworkItems": .array(
        identifiers.map {
          .dictionary([
            "SKAdNetworkIdentifier": .string($0),
          ])
        }
      ),
    ]) { _, new in new }
  }
}
