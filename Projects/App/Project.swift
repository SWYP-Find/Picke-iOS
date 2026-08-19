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
    .Domain(.AppUpdate),
    .Domain(.Attendance),
    .Domain(.Auth),
    .Domain(.Battle),
    .Domain(.Comment),
    .Domain(.Home),
    .Domain(.Notification),
    .Domain(.Perspective),
    .Domain(.Profile),
    .Domain(.Search),
    .Data(.AppUpdate),
    .Service(.AudioPlayer),
    .Service(.Analytics),
    .Presentation(implements: .Presentation),
    .Domain(implements: .Domain),
    .Data(implements: .Data),
    .Network(implements: .NetworkModule),
    .Network(implements: .NetworkToken),
    .Core(.PickeCore),
    .Core(.PickeStorage),
    .Service(.Device),
    .Service(.Ad), // 앱 시작 전면 팝업 광고
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
