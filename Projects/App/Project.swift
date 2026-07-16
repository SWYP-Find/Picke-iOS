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
