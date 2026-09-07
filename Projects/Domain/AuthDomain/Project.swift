import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AuthDomain"),
  bundleId: .appBundleID(name: ".AuthDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.storage, .interface),
    .SPM.composableArchitecture,
    .SPM.logMarco,
    .service(.api),
    .service(.apiEndpoint),
    .service(.auth, .interface),
    .core(.network),
    .core(.network, .interface),
    .SPM.googleSignIn,
  ],
  interfaceDependencies: [
    // UserSessionSharedKey 가 PersistentSharedKey(PickeStorageInterface)와 Sharing 을 직접 쓴다.
    .core(.storage, .interface),
    .SPM.sharing,
    .SPM.composableArchitecture,
  ]
)
