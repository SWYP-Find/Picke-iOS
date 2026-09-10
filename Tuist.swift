import ProjectDescription

let tuist = Tuist(
  // 대시보드와 캐시는 로컬 개발에서만 사용한다.
  fullHandle: Environment.isCI ? nil : "picke2026/picke",
  cache: .cache(upload: !Environment.isCI),
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
      enableCaching: !Environment.isCI
    ),
    installOptions: .options(),
    cacheOptions: .options(
      profiles: .profiles(default: Environment.isCI ? .none : .onlyExternal)
    )
  )
)
