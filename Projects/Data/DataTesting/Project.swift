import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DataTesting"),
  bundleId: .appBundleID(name: ".DataTesting"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.appUpdate, .interface),
    
    .service(.audioPlayer),
  ],
  sources: ["Sources/**"]
)
