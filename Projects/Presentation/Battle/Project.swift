import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .feature(.Battle),
  bundleId: .appBundleID(name: ".Battle"),
  settings: .settings(),
  dependencies: [
    .Presentation(.Chat, .implementation),
    .Shared(implements: .Shared),
    .Domain(implements: .UseCase),
    .SPM.composableArchitecture,
    .SPM.tcaFlow,
    .SPM.kingfisher,
  ]
)
