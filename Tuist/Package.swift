// swift-tools-version: 6.2
@preconcurrency import PackageDescription

#if TUIST
  @preconcurrency import ProjectDescription

  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture": .framework,
      "Dependencies": .framework,
      "TCAFlow": .framework,
      "Moya": .framework,
      "LogMacro": .framework,
      "AsyncMoya": .framework,
      "AppAuth": .framework,
      "AppAuthCore": .framework,
      "GTMAppAuth": .framework,
      "GTMSessionFetcherCore": .framework,
      "IssueReporting": .framework,
      "IssueReportingPackageSupport": .framework,
      "XCTestDynamicOverlay": .framework,
      "Clocks": .framework,
      "ConcurrencyExtras": .framework,
      "WeaveDI": .framework,
      "ReactiveSwift": .framework,
      "SDWebImageSwiftUI": .framework,
      "Mixpanel": .framework,
      "MixpanelSessionReplay": .framework,
      "GoogleMobileAds": .framework,
      "Sentry": .framework,
      "SentrySwiftUI": .framework,
    ],
    // 외부 SPM 패키지 타깃(Sentry/WebKit 등)에도 Explicitly Built Modules 비활성화.
    // (Xcode 26 에서 Sentry→WebKit 빌드 시 system Network 모듈의 os_object 미제공 +
    //  "implicit use of module files is disabled" 에러가 나므로 패키지 레벨에서 끈다)
    baseSettings: .settings(
      base: [
        "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
        "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
      ]
    )
  )
#endif

let package = Package(
  name: "TimeSpot",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.25.5"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.0"),
    .package(url: "https://github.com/Roy-wonji/TCAFlow.git", exact: "1.1.3"),
    .package(url: "https://github.com/Roy-wonji/WeaveDI.git", from: "3.4.1"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0"),
    .package(url: "https://github.com/Roy-wonji/AsyncMoya", from: "1.1.8"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "2.0.0"),
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.7.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.2.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.12.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.1.4"),
    .package(url: "https://github.com/mixpanel/mixpanel-swift.git", from: "5.1.3"),
    .package(url: "https://github.com/mixpanel/mixpanel-ios-session-replay-package", exact: "1.4.0"),
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "12.0.0"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.58.4"),
  ]
)
