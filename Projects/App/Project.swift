import DependencyPackagePlugin
import DependencyPlugin
import ProjectDescription
import ProjectTemplatePlugin

private let appName = Project.Environment.appName

let project = Project.makeAppModule(
  name: appName,
  bundleId: .mainBundleID(),
  product: .app,
  settings: .appMainSetting,
  scripts: [.SentryUploadString],
  dependencies: [
    // 화면·도메인·데이터 구현은 각 레이어의 조립 경계 하나로 들어온다.
    .featureAssembly,
    .SPM.googleMobileAds,
    .SPM.kingfisher,
  ],
  resources: ["Resources/**"],
  infoPlist: .appInfoPlist,
  entitlements: .file(path: "../../Entitlements/Picke.entitlements"),
  schemes: Scheme.appSchemes(appName: appName),
  hasTests: false
)