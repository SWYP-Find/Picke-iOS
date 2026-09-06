import DependencyPackagePlugin
import DependencyPlugin
import ProjectDescription
import ProjectTemplatePlugin

private let appName = Project.Environment.appName

let project = Project.configure(
  moduleType: .app,
  name: appName,
  bundleId: .mainBundleID(),
  product: .app,
  settings: .appMainSetting,
  scripts: [.SentryUploadString],
  dependencies: [
    // 화면·도메인·데이터 구현은 각 레이어의 조립 경계 하나로 들어온다.
    .featureAssembly,
    .domainAssembly,
    // Core·Service 구현은 조립 경계 하나로 들어온다.
    // 앱 시작 전면 팝업 광고(Ad)도 여기에 포함된다.
    .serviceAssembly,
    .core(.network),
    .core(.network, .interface),
    .SPM.googleMobileAds,
    .SPM.firebaseCrashlytics,
    .SPM.mixpanel,
    .SPM.mixpanelSessionReplay,
    .SPM.kingfisher,
    .SPM.sdwebImageCore,
    .SPM.sentrySwiftUI,
  ],
  sources: ["Sources/**"],
  resources: ["Resources/**"],
  infoPlist: .appInfoPlist,
  entitlements: .file(path: "../../Entitlements/Picke.entitlements"),
  schemes: Scheme.appSchemes(appName: appName),
  hasTests: false
)
