//
//  Project.swift
//  Web
//
//  Created by Picke on 10/11/26.
//

import Foundation

import DependencyPackagePlugin
import DependencyPlugin
import ProjectTemplatePlugin

import ProjectDescription

let project = Project.makeModule(
  name: "Web",
  bundleId: .appBundleID(name: ".Web"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .ui(.designKit),
    .SPM.composableArchitecture,
  ],
  hasTests: true,
  hasInterface: true,
  hasTesting: false
)