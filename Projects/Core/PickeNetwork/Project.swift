//
//  Project.swift
//  PickeNetwork
//

import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeNetwork",
  bundleId: .appBundleID(name: ".PickeNetwork"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .core(.logger),
    .SPM.alamofire,
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.alamofire,
    .SPM.dependencies,
  ],
  hasTesting: false
)