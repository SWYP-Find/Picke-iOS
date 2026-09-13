import Foundation
import ProjectDescription

let usesLocalCacheOnly = ProcessInfo.processInfo.environment["TUIST_LOCAL_CACHE_ONLY"] == "true"

let tuist = Tuist(
  // 일반 로컬 generate/project show 는 Dashboard 에 연결하고,
  // cache warm 프로세스만 로컬 저장소를 쓰도록 handle 을 비운다.
  fullHandle: "picke2026/picke",
  xcodeCache: .xcodeCache(
    upload: true
  ),
  project: .tuist(
    compatibleXcodeVersions: .all,
    swiftVersion: .some("6.0.0"),
    plugins: [
      .local(path: .relativeToRoot("Plugins/ProjectTemplatePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPackagePlugin")),
      .local(path: .relativeToRoot("Plugins/DependencyPlugin")),
    ],
    generationOptions: .options(
      staticSideEffectsWarningTargets: .all,
      optionalAuthentication: true,
      enableCaching: true
    ),
    installOptions: .options(),
    cacheOptions: .options(
      profiles: .profiles(default: .onlyExternal)
    )
  )
)
