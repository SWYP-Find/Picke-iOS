// swift-tools-version: 6.2
@preconcurrency import PackageDescription

#if TUIST
  @preconcurrency import ProjectDescription

  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture": .staticFramework,
      "Dependencies": .staticFramework,
      "TCAFlow": .staticFramework,
      "Moya": .staticFramework,
      "LogMacro": .staticFramework,
      "AsyncMoya": .staticFramework,
      "AppAuth": .staticFramework,
      "AppAuthCore": .staticFramework,
      "GTMAppAuth": .staticFramework,
      "GTMSessionFetcherCore": .staticFramework,
      "IssueReporting": .staticFramework,
      "IssueReportingPackageSupport": .staticFramework,
      "XCTestDynamicOverlay": .staticFramework,
      "Clocks": .staticFramework,
      "ConcurrencyExtras": .staticFramework,
      "WeaveDI": .staticFramework,
      "ReactiveSwift": .staticFramework,
      "SDWebImageSwiftUI": .staticFramework,
      "Mixpanel": .staticFramework,
      "MixpanelSessionReplay": .staticFramework,
      "GoogleMobileAds": .staticFramework,
    ],
    // swift-navigation / swift-case-paths 매크로(SwiftNavigationMacros, CasePathsMacrosSupport)가
    // Xcode Explicit Modules 아카이브에서 "header 'CasePathsMacrosSupport-Swift.h' not found"로
    // 빌드 실패하는 버그 회피 — SPM 의존성 타깃 전체에 Explicit Modules 비활성을 직접 적용.
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
  ]
)
