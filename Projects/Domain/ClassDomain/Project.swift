//
//  Project.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "ClassDomain",
  bundleId: .appBundleID(name: ".ClassDomain"),
  product: .framework,
  settings: .settings(),
  dependencies: [
    .serviceAssembly,
    .service(.apiEndpoint),
  ],
  testDependencies: [
    .service(.apiEndpoint),
  ],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .SPM.composableArchitecture,
  ],
  hasTesting: false
)
