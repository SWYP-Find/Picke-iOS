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
      "TCAFlow": .framework,
      "Alamofire": .framework,
      "LogMacro": .framework,
      "AppAuth": .framework,
      "AppAuthCore": .framework,
      "GTMAppAuth": .framework,
      "GTMSessionFetcherCore": .framework,
      "IssueReporting": .framework,
      "IssueReportingPackageSupport": .framework,
      "XCTestDynamicOverlay": .framework,
      "Clocks": .framework,
      "ConcurrencyExtras": .framework,
      "ReactiveSwift": .framework,
      "SDWebImage": .framework,
      "SDWebImageSwiftUI": .framework,
      "Mixpanel": .framework,
      "MixpanelSessionReplay": .framework,
      "GoogleMobileAds": .framework,
      "Sentry": .framework,
      "SentrySwiftUI": .framework,

      // Sharing·SQLiteData 는 여러 동적 모듈이 함께 쓰므로 단일 런타임으로 공유한다.
      // 버전 마커(Sharing1/2)는 정적으로 링크해 앱이 Sharing1.framework 를 찾지 않게 한다.
      "Sharing1": .staticFramework,
      "Sharing2": .staticFramework,
      "SQLiteData": .framework,
      "GRDB": .framework,
      "GRDBSQLite": .framework,
      "GRDB_GRDB": .framework,
      "StructuredQueries": .framework,
      "StructuredQueriesCore": .framework,
      "StructuredQueriesSQLite": .framework,
      "StructuredQueriesSQLiteCore": .framework,
    ],
    // 외부 SPM 패키지 타깃(Sentry/WebKit 등)에도 Explicitly Built Modules 비활성화.
    // (Xcode 26 에서 Sentry→WebKit 빌드 시 system Network 모듈의 os_object 미제공 +
    //  "implicit use of module files is disabled" 에러가 나므로 패키지 레벨에서 끈다)
    baseSettings: .settings(
      base: [
        "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
        "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
        // Xcode 26 의 XCTest 가 먼저 로드하는 애플 private `Sharing` 모듈과 충돌해
        // xctest 부팅이 깨진다. Point-Free 구현은 다른 모듈명으로 빌드하고
        // 소스의 `import Sharing` 은 별칭으로 이어 붙인다.
        "OTHER_SWIFT_FLAGS": "$(inherited) -module-alias Sharing=PickePointFreeSharing",
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
    ),
    targetSettings: [
      // 위 module-alias 와 짝. 산출물 이름 자체를 바꿔 시스템 Sharing.framework 를 가리지 않는다.
      "Sharing": .settings(base: ["PRODUCT_NAME": "PickePointFreeSharing"]),
    ]
  )
#endif

let package = Package(
  name: "TimeSpot",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
    // 1.13+의 traits 조건부 Clocks/CombineSchedulers 의존성이 Tuist에서 누락되는 문제를 피한다.
    // 소스 빌드와 바이너리 캐시가 같은 그래프를 쓰도록 마지막 비조건부 버전을 고정한다.
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.12.0"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", exact: "1.11.0"),
    .package(url: "https://github.com/Roy-wonji/TCAFlow.git", exact: "1.1.8"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "2.0.0"),
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.7.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.2.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.12.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.1.4"),
    .package(url: "https://github.com/mixpanel/mixpanel-swift.git", from: "5.1.3"),
    .package(url: "https://github.com/mixpanel/mixpanel-ios-session-replay-package", exact: "1.4.0"),
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "12.0.0"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", from: "9.21.0"),
    // 카카오 AdFit — CocoaPods 지원 종료(3.18.6~)로 SPM 만 제공. 배포물은 binaryTarget(xcframework)
    // 하나뿐이라 productTypes 전환 대상이 아니다(이미 DYLIB 로 빌드된 동적 프레임워크).
    .package(url: "https://github.com/adfit/adfit-spm.git", exact: "3.21.24"),
  ]
)
