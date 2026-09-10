import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "ServiceAssembly",
  bundleId: .appBundleID(name: ".ServiceAssembly"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .coreAssembly,
    .service(.api),
    .service(.apiEndpoint),
    .service(.analytics),
    .service(.config),
    .service(.audioPlayer),
    .service(.device),
    .service(.auth),
    .service(.auth, .interface),
  ],
  hasTests: true
)