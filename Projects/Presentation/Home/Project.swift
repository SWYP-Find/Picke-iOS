import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeAppModule(
  name: "Home",
  bundleId: .appBundleID(name: ".Home"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .SPM.tcaFlow,
    .SPM.kingfisher,
    .Domain(implements: .UseCase),
    .Shared(implements: .Shared),
    .Presentation(implements: .Chat),
    .Presentation(implements: .Notification),
  ],
  sources: ["Sources/**"]
)
