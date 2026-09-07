import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .module(name: "DomainAssembly"),
  bundleId: .appBundleID(name: ".DomainAssembly"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.appUpdate),
    .domain(.attendance),
    .domain(.auth),
    .domain(.battle),
    .domain(.search),
    .domain(.comment),
    .domain(.home),
    .domain(.notification),
    .domain(.perspective),
    .domain(.profile),
  ],
  sources: ["Sources/**"],
  hasTests: true
)
