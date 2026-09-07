import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .module(name: "ServiceAssembly"),
  bundleId: .appBundleID(name: ".ServiceAssembly"),
  product: .framework,
  settings: .settings(),
  // SDK 를 링크하는 서비스 구현을 한곳에서 묶는 조립 경계.
  dependencies: [
    .coreAssembly,
    .service(.api),
    .service(.apiEndpoint),
    .service(.analytics),
    .service(.audioPlayer),
    .service(.device),
    .service(.auth),
    .service(.auth, .interface),
  ],
  sources: ["Sources/**"],
  hasTests: true
)
