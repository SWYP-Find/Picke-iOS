//
//  Project+Feature.swift
//  ProjectTemplatePlugin
//
//  feature 모듈 타입의 Project 구성 (MicroFeature).
//  타깃: Interface + 구현 + Testing + Tests.
//

import ProjectDescription

extension Project {
  static func configureFeature(
    name: String,
    bundleId: String,
    platform _: Platform = .iOS,
    product: Product = .staticFramework,
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    interfaceDependencies: [ProjectDescription.TargetDependency] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    testingDependencies: [ProjectDescription.TargetDependency] = [],
    resources: ProjectDescription.ResourceFileElements? = nil,
    schemes: [ProjectDescription.Scheme] = []
  ) -> Project {
    let interfaceTargetName = "\(name)Interface"
    let testingTargetName = "\(name)Testing"

    let interfaceTarget: Target = .target(
      name: interfaceTargetName,
      destinations: destinations,
      product: product,
      bundleId: "\(bundleId).Interface",
      deploymentTargets: deploymentTarget,
      infoPlist: .default,
      buildableFolders: ["Interface"],
      dependencies: interfaceDependencies,
      settings: suppressWarningsSettings
    )

    let featureTarget: Target = .target(
      name: name,
      destinations: destinations,
      product: product,
      bundleId: bundleId,
      deploymentTargets: deploymentTarget,
      infoPlist: .default,
      buildableFolders: resources != nil ? ["Sources", "Resources"] : ["Sources"],
      dependencies: [.target(name: interfaceTargetName)] + dependencies,
      settings: suppressWarningsSettings
    )

    let testingTarget: Target = .target(
      name: testingTargetName,
      destinations: destinations,
      product: product,
      bundleId: "\(bundleId).Testing",
      deploymentTargets: deploymentTarget,
      infoPlist: .default,
      buildableFolders: ["Testing"],
      dependencies: [
        .target(name: interfaceTargetName),
        .target(name: name),
      ] + testingDependencies,
      settings: suppressWarningsSettings
    )

    let testTarget = makeTestsTarget(
      name: name,
      bundleId: bundleId,
      destinations: destinations,
      deploymentTarget: deploymentTarget,
      dependencies: [
        .target(name: name),
        .target(name: testingTargetName),
      ]
    )

    return Project(
      name: name,
      settings: settings.injectingModuleConfigurationsIfNeeded(),
      targets: [
        interfaceTarget,
        featureTarget,
        testingTarget,
        testTarget,
      ],
      schemes: schemes,
      fileHeaderTemplate: .default
    )
  }
}
