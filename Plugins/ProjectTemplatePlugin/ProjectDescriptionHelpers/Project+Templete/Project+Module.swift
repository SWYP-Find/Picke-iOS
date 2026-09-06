//
//  Project+Module.swift
//  ProjectTemplatePlugin
//
//  일반/엄브렐러 모듈 타입의 Project 구성.
//

import ProjectDescription

extension Project {
  static func configureModule(
    name: String = Environment.appName,
    bundleId: String,
    platform _: Platform = .iOS,
    product: Product,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    sources _: ProjectDescription.SourceFilesList = ["Sources/**"],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false,
    demoDisplayName: String? = nil
  ) -> Project {
    let moduleTarget: Target = .target(
      name: name,
      destinations: destinations,
      product: product,
      bundleId: bundleId,
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      buildableFolders: resources != nil ? ["Sources", "Resources"] : ["Sources"],
      entitlements: entitlements,
      scripts: scripts,
      dependencies: dependencies,
      settings: suppressWarningsSettings
    )

    var targets: [Target] = [moduleTarget]

    if hasTests {
      targets.append(
        makeTestsTarget(
          name: name,
          bundleId: bundleId,
          destinations: destinations,
          deploymentTarget: deploymentTarget,
          dependencies: [.target(name: name)]
        )
      )
    }

    var allSchemes = schemes
    if let demoDisplayName {
      let demoName = "\(name)Demo"
      targets.append(
        .target(
          name: demoName,
          destinations: destinations,
          product: .app,
          bundleId: "\(bundleId).Demo",
          deploymentTargets: deploymentTarget,
          infoPlist: .extendingDefault(with: [
            "UILaunchScreen": [:],
            "CFBundleDisplayName": .string(demoDisplayName),
          ]),
          buildableFolders: ["Demo"],
          dependencies: [.target(name: name)],
          settings: suppressWarningsSettings
        )
      )
      allSchemes.append(
        .scheme(
          name: demoName,
          shared: true,
          buildAction: .buildAction(targets: [.target(demoName)]),
          runAction: .runAction(configuration: .stage, executable: "\(demoName)")
        )
      )
    }

    return Project(
      name: name,
      packages: packages,
      settings: settings.injectingModuleConfigurationsIfNeeded(),
      targets: targets,
      schemes: allSchemes,
      fileHeaderTemplate: .default
    )
  }
}
