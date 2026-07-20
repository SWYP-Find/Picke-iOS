import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "AttendanceDomain"),
  bundleId: .appBundleID(name: ".AttendanceDomain"),
  settings: .settings(),
  dependencies: [.SPM.weaveDI, .SPM.composableArchitecture],
  interfaceDependencies: [.SPM.weaveDI, .SPM.composableArchitecture]
)
