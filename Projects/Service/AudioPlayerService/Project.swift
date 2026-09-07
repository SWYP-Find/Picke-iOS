import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.configure(
  moduleType: .microModule(name: "AudioPlayerService"),
  bundleId: .appBundleID(name: ".AudioPlayerService"),
  product: .framework,
  settings: .settings(),
  // AVFoundation 은 시스템 프레임워크라 별도 선언이 필요 없다.
  dependencies: [
    .SPM.composableArchitecture,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ]
)
