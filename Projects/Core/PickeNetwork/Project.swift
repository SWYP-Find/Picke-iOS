//
//  Project.swift
//  PickeNetwork
//

import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.configure(
  moduleType: .microModule(name: "PickeNetwork"),
  bundleId: .appBundleID(name: ".PickeNetwork"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .SPM.alamofire,
    .SPM.logMarco,
  ],
  interfaceDependencies: [
    .SPM.alamofire,
    .SPM.dependencies,
  ]
)
