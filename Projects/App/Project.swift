import DependencyPackagePlugin
import DependencyPlugin
import ProjectDescription
import ProjectTemplatePlugin

private let appName = Project.Environment.appName

/// 타깃 이름 ↔ 빌드 configuration 을 1:1 로 고정한 스킴.
/// Tuist 자동생성 스킴은 Run 을 Debug(=Dev.xcconfig, dev.picke.store)로 잡아
/// Stage 타깃도 dev 서버를 타는 문제가 있어, 이름에 맞는 config 로 명시한다.
private func appScheme(name: String, configuration: ConfigurationName) -> Scheme {
  .scheme(
    name: name,
    shared: true,
    buildAction: .buildAction(targets: ["\(name)"]),
    runAction: .runAction(configuration: configuration),
    archiveAction: .archiveAction(configuration: configuration),
    profileAction: .profileAction(configuration: configuration),
    analyzeAction: .analyzeAction(configuration: configuration)
  )
}

let project = Project.makeAppModule(
  name: appName,
  bundleId: .mainBundleID(),
  product: .app,
  settings: .appMainSetting,
  scripts: [],
  dependencies: [
    .Presentation(implements: .Presentation),
    .Data(implements: .Repository),
    .Shared(implements: .Shared),
    .SPM.googleMobileAds,
    .SPM.firebaseCrashlytics,
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.kingfisher,

  ],
  sources: ["Sources/**"],
  resources: ["Resources/**"],
  infoPlist: .appInfoPlist,
  entitlements: .file(path: "../../Entitlements/Picke.entitlements"),
  schemes: [
    appScheme(name: appName, configuration: .release),
    appScheme(name: "\(appName)-Debug", configuration: .debug),
    appScheme(name: "\(appName)-Stage", configuration: .stage),
    appScheme(name: "\(appName)-Prod", configuration: .prod),
  ],
  hasTests: false
)
