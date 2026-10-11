//
//  Project.swift
//  PickeCoreLogger
//
//  Created by Picke on 10/11/26.
//

import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "PickeCoreLogger",
  bundleId: .appBundleID(name: ".PickeCoreLogger"),
  product: .framework,
  settings: .settings(),
  dependencies: [
  ],
  hasTests: true
)