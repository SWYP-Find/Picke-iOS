import Foundation
import ProjectDescription

let usesLocalCacheOnly = ProcessInfo.processInfo.environment["TUIST_LOCAL_CACHE_ONLY"] == "true"

let tuist = Tuist(
  // 일반 로컬 generate/project show 는 Dashboard 에 연결하고,
  // cache warm 프로세스만 로컬 저장소를 쓰도록 handle 을 비운다.
  fullHandle: Environment.isCI || usesLocalCacheOnly ? nil : "picke2026/picke",
  cache: .cache(upload: false),
  project: .tuist(
    compatibleXcodeVersions: .all,
    swiftVersion: .some("6.0.0"),
    plugins: [
      .local(path: .relativeToRoot("Plugins/ProjectTemplatePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPackagePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPlugin")),
    ],
    generationOptions: .options(
      // 🔒 패키지 버전 잠금 비활성화 여부 (기본 false)
      //   true  = Package.resolved 고정 무시(최신으로 다시 풀기)
      //   false = 기존 잠금 유지(권장)
      disablePackageVersionLocking: false,

      // ⚠️ 사이드 이펙트(스크립트 등) 경고를 어떤 타겟에 표시할지
      //   .all / .selected([...]) / .none
      staticSideEffectsWarningTargets: .all,
      optionalAuthentication: true,
      // 현재 Explicit Modules를 끈 빌드 설정에서는 Xcode 컴파일 캐시를 사용할 수 없다.
      // 로컬 개발은 아래의 외부 모듈 바이너리 캐시를 사용한다.
      enableCaching: false
    ),
    installOptions: .options(),
    cacheOptions: .options(
      profiles: .profiles(default: Environment.isCI ? .none : .onlyExternal)
    )
  )
)
