// swift-tools-version: 6.2
@preconcurrency import PackageDescription

#if TUIST
  @preconcurrency import ProjectDescription

  let packageSettings = PackageSettings(
    productTypes: [
      // 동적 전환: PickeDesignKit(동적)이 이 라이브러리들을 정적 링크하면 앱 바이너리와
      // 각각 중복 복사되어 ObjC 클래스가 2벌 등록되고 "spurious casting failures/
      // mysterious crashes" + NavigationRequestObserver 다중 갱신을 유발한다.
      // 동적이면 앱·프레임워크가 단일 사본을 공유한다.
      "ComposableArchitecture": .framework,
      "Dependencies": .framework,
      "Perception": .framework,
      "Sharing": .framework,
      "TCAFlow": .staticFramework,
      "Moya": .staticFramework,
      "Alamofire": .staticFramework,
      "LogMacro": .staticFramework,
      "AsyncMoya": .staticFramework,
      "AppAuth": .framework,
      "AppAuthCore": .framework,
      "GTMAppAuth": .framework,
      "GTMSessionFetcherCore": .framework,
      "IssueReporting": .framework,
      "IssueReportingPackageSupport": .staticFramework,
      "XCTestDynamicOverlay": .staticFramework,
      "Clocks": .staticFramework,
      "ConcurrencyExtras": .staticFramework,
      "WeaveDI": .framework,
      "ReactiveSwift": .staticFramework,
      "SDWebImageSwiftUI": .staticFramework,
      "Mixpanel": .staticFramework,
      "MixpanelSessionReplay": .staticFramework,
      "GoogleMobileAds": .framework,
      "Sentry": .staticFramework,
      "SentrySwiftUI": .staticFramework,
    ],
    // 외부 SPM 패키지 타깃(Sentry/WebKit 등)에도 Explicitly Built Modules 비활성화.
    // (Xcode 26 에서 Sentry→WebKit 빌드 시 system Network 모듈의 os_object 미제공 +
    //  "implicit use of module files is disabled" 에러가 나므로 패키지 레벨에서 끈다)
    baseSettings: .settings(
      base: [
        "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
        "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
      ],
      // 외부 SPM 패키지도 앱과 동일한 커스텀 컨피그(Stage/Prod/Release)를 갖게 한다.
      // 이게 없으면 패키지는 기본 [Debug, Release]만 생성 → Stage 빌드 시 리소스 번들이
      // Release-iphonesimulator 에만 만들어져 앱의 Stage-iphonesimulator Copy Bundle Resources
      // 단계가 lstat 실패(SDWebImage_SDWebImage.bundle 등)로 깨진다.
      configurations: [
        .debug(name: "Stage"),
        .release(name: "Prod"),
        .release(name: "Release"),
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
