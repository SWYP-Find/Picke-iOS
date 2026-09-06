import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "Profile"),
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .core(.storage, .interface),
    .service(.device, .interface),
    .service(.analytics, .interface),
    .domain(.profile, .interface),
    .domain(.auth, .interface),
    .domain(.battle, .interface),
    .domain(.notification, .interface),

    .core(.thirdParty),
    .feature(.ad), // 마이페이지 하단 배너 광고
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ],
  interfaceDependencies: [
    .domain(.profile, .interface),
  ]
)
