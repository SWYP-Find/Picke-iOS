import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Profile",
  bundleId: .appBundleID(name: ".Profile"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .ui(.sharedUI),
    .core(.coreUtility),
    .service(.auth, .interface),
    .service(.device, .interface),
    .service(.analytics, .interface),
    .domain(.profile, .interface),
    .domain(.auth, .interface),
    .domain(.battle, .interface),
    .domain(.notification, .interface),
    .feature(.ad, .implementation), // 마이페이지 하단 배너 광고
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.profile, .interface),
  ],
  hasTesting: false
)