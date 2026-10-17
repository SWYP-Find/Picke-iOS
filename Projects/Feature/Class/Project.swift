//
//  Project.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import DependencyPackagePlugin
import DependencyPlugin
import Foundation
import ProjectDescription
import ProjectTemplatePlugin

let project = Project.makeModule(
  name: "Class",
  bundleId: .appBundleID(name: ".Class"),
  product: .staticFramework,
  settings: .settings(),
  dependencies: [
    .core(.coreUtility),
    .ui(.designKit),
    .ui(.sharedUI),
    .domain(.battle, .interface),
    .domain(.classroom, .interface),
    .SPM.composableArchitecture,
  ],
  testDependencies: [.SPM.issueReportingTestSupport],
  sourceFolderExclusions: [".omc", "ClassRecommend/View/.omc"],
  hasTests: true,
  hasInterface: true,
  interfaceDependencies: [
    .domain(.classroom, .interface),
  ],
  hasTesting: false
)
