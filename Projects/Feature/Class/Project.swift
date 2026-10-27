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
    .service(.audioPlayer, .interface),
    .service(.analytics, .interface),
    .domain(.battle, .interface),
    .domain(.auth, .interface),
    .domain(.classroom, .interface),
    .domain(.comment, .interface),
    .domain(.home, .interface),
    .domain(.perspective, .interface),
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
