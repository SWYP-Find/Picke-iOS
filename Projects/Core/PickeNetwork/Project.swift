//
//  Project.swift
//  PickeNetwork
//

import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

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
