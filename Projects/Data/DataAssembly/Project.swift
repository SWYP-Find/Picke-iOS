import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DataAssembly"),
  bundleId: .appBundleID(name: ".DataAssembly"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .data(.appUpdate),
    .model,
    .apiEndpoint,
    .data(.attendance),
    .data(.auth),
    .data(.battle),
    .data(.search),
    .data(.comment),
    .data(.home),
    .data(.notification),
    .data(.perspective),
    .data(.profile),
  ],
  sources: ["Sources/**"]
)
