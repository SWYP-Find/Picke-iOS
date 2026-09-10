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
    .core(.logger),
    .core(.storage, .interface),
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
    .feature(.featureSharedUI, .implementation), // 마이페이지 하단 배너 광고
    // 리워드 광고 계약(RewardedAdClient)은 Ad Interface 에서 온다.
    .feature(.ad),
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
