//
//  Extension+TargetDependencySPM.swift
//  DependencyPackagePlugin
//
//  Created by Picke on 4/19/24.
//

import ProjectDescription

public extension TargetDependency.SPM {
  static let alamofire = TargetDependency.external(name: "Alamofire", condition: .none)
  static let logMarco = TargetDependency.external(name: "LogMacro", condition: .none)

  static let composableArchitecture = TargetDependency.external(name: "ComposableArchitecture", condition: .none)
  // Release 구성에서도 TCA 검증 실패를 기록하도록 테스트 타깃에서만 링크한다.
  static let issueReportingTestSupport = TargetDependency.external(name: "IssueReportingTestSupport", condition: .none)
  static let dependencies = TargetDependency.external(name: "Dependencies", condition: .none)
  static let sharing = TargetDependency.external(name: "Sharing", condition: .none)
  static let sqliteData = TargetDependency.external(name: "SQLiteData", condition: .none)
  static let identifiedCollections = TargetDependency.external(name: "IdentifiedCollections", condition: .none)
  static let tcaFlow = TargetDependency.external(name: "TCAFlow", condition: .none)
  static let concurrencyExtras = TargetDependency.external(name: "ConcurrencyExtras", condition: .none)
  static let sdwebImageCore = TargetDependency.external(name: "SDWebImage", condition: .none)
  static let sdwebImage = TargetDependency.external(name: "SDWebImageSwiftUI", condition: .none)
  static let kingfisher = TargetDependency.external(name: "Kingfisher", condition: .none)

  static let googleSignIn = TargetDependency.external(name: "GoogleSignIn", condition: .none)
  static let appAuth: TargetDependency = .external(name: "AppAuth")
  static let firebaseCrashlytics = TargetDependency.external(name: "FirebaseCrashlytics", condition: .none)
  static let firebaseMessaging = TargetDependency.external(name: "FirebaseMessaging", condition: .none)
  static let googleUtilities = TargetDependency.external(name: "GoogleUtilities", condition: .none)
  static let googleMobileAds = TargetDependency.external(name: "GoogleMobileAds", condition: .none)
  static let mixpanel = TargetDependency.external(name: "Mixpanel", condition: .none)
  static let mixpanelSessionReplay = TargetDependency.external(name: "MixpanelSessionReplay", condition: .none)
  static let adFit = TargetDependency.external(name: "AdFitSDK", condition: .none)
  // Sentry 9.34.0 이하 바이너리 xcframework 는 서명 인증서가 폐기돼(sentry-cocoa #9633) 소스 빌드 제품을 쓴다.
  static let sentry = TargetDependency.external(name: "SentrySPM", condition: .none)
}
