import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "AuthDomain",
  bundleId: .appBundleID(name: ".AuthDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .core(.storage, .interface),
    .service(.auth, .interface),
    .SPM.googleSignIn,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    // UserSessionSharedKey 가 PersistentSharedKey(PickeStorageInterface)와 Sharing 을 직접 쓴다.
    .core(.storage, .interface),
    .SPM.sharing,
    .SPM.composableArchitecture,
  ],
  hasTesting: true
)