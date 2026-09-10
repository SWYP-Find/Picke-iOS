import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "DomainAssembly",
  bundleId: .appBundleID(name: ".DomainAssembly"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .domain(.appUpdate, .implementation),
    .domain(.attendance, .implementation),
    .domain(.auth, .implementation),
    .domain(.battle, .implementation),
    .domain(.search, .implementation),
    .domain(.comment, .implementation),
    .domain(.home, .implementation),
    .domain(.notification, .implementation),
    .domain(.perspective, .implementation),
    .domain(.profile, .implementation),
  ],
  hasTests: true
)