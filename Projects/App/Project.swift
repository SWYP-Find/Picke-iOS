import DependencyPackagePlugin
import DependencyPlugin
import ProjectDescription
import ProjectTemplatePlugin

private let appName = Project.Environment.appName

/// 단일 앱 타깃(appName) 을 공유하되, 스킴별로 빌드 configuration 만 1:1 로 고정한다.
/// `name` 은 스킴 표시 이름(Picke / Picke-Debug / …)이고, 빌드 대상은 항상 단일 타깃 `appName`.
/// Tuist 자동생성 스킴은 Run 을 Debug(=Dev.xcconfig, dev.picke.store)로 잡아
/// Stage 도 dev 서버를 타는 문제가 있어, 스킴마다 맞는 config 로 명시한다.
private func appScheme(name: String, configuration: ConfigurationName) -> Scheme {
  .scheme(
    name: name,
    shared: true,
    buildAction: .buildAction(targets: ["\(appName)"]),
    runAction: .runAction(configuration: configuration),
    archiveAction: .archiveAction(configuration: configuration),
    profileAction: .profileAction(configuration: configuration),
    analyzeAction: .analyzeAction(configuration: configuration)
  )
}

let project = Project.configure(
  moduleType: .app,
  name: appName,
  bundleId: .mainBundleID(),
  product: .app,
  settings: .appMainSetting,
  scripts: [.SentryUploadString],
  dependencies: [
    .Presentation(implements: .Presentation),
    .Domain(implements: .Domain),
    .Data(implements: .Data),
    .Network(implements: .NetworkModule),
    .Shared(implements: .Shared),
    .SPM.googleMobileAds,
    .SPM.firebaseCrashlytics,
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.kingfisher,
    .SPM.sentrySwiftUI,

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
