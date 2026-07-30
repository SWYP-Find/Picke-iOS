import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AudioPlayerService"),
  bundleId: .appBundleID(name: ".AudioPlayerService"),
  product: .staticFramework,
  settings: .settings(),
  // AVFoundation 은 시스템 프레임워크라 별도 선언이 필요 없다.
  dependencies: [
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ],
  interfaceDependencies: [
    .SPM.composableArchitecture,
    .SPM.weaveDI,
  ]
)
