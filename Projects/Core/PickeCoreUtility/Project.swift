//
//  Project.swift
//  PickeCoreUtility
//
//  Created by Picke on 10/11/26.
//

import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeCoreUtility",
  bundleId: .appBundleID(name: ".PickeCoreUtility"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .SPM.dependencies,
    .core(.network),
  ],
  hasTests: true
)
