//
//  Project+Template.swift
//  ProjectTemplatePlugin
//
//  모듈 타입에 따라 Project 를 구성하는 단일 진입점.
//  각 Project.swift 는 이 함수만 호출한다.
//

import ProjectDescription

public extension Project {
  static func configure(
    moduleType: ModuleType,
    name: String = Environment.appName,
    bundleId: String,
    platform: Platform = .iOS,
    product: Product = .staticFramework,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    interfaceDependencies: [ProjectDescription.TargetDependency] = [],
    testingDependencies: [ProjectDescription.TargetDependency] = [],
    sources: ProjectDescription.SourceFilesList = ["Sources/**"],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false,
    demoDisplayName: String? = nil
  ) -> Project {
    switch moduleType {
    case .app:
      return configureApp(
        name: name,
        bundleId: bundleId,
        platform: platform,
        product: product,
        packages: packages,
        deploymentTarget: deploymentTarget,
        destinations: destinations,
        settings: settings,
        scripts: scripts,
        dependencies: dependencies,
        sources: sources,
        resources: resources,
        infoPlist: infoPlist,
        entitlements: entitlements,
        schemes: schemes,
        hasTests: hasTests
      )
    case let .module(name):
      return configureModule(
        name: name,
        bundleId: bundleId,
        platform: platform,
        product: product,
        packages: packages,
        deploymentTarget: deploymentTarget,
        destinations: destinations,
        settings: settings,
        scripts: scripts,
        dependencies: dependencies,
        sources: sources,
        resources: resources,
        infoPlist: infoPlist,
        entitlements: entitlements,
        schemes: schemes,
        hasTests: hasTests,
        demoDisplayName: demoDisplayName
      )
    case let .microModule(name):
      return configureFeature(
        name: name,
        bundleId: bundleId,
        platform: platform,
        product: product,
        deploymentTarget: deploymentTarget,
        destinations: destinations,
        settings: settings,
        interfaceDependencies: interfaceDependencies,
        dependencies: dependencies,
        testingDependencies: testingDependencies,
        resources: resources,
        schemes: schemes
      )
    }
  }
}

public extension Scheme {
  static func makeScheme(target: ConfigurationName, name: String) -> Scheme {
    return Scheme.scheme(
      name: name,
      shared: true,
      buildAction: .buildAction(targets: ["\(name)"]),
      testAction: .targets(
        ["\(name)Tests"],
        configuration: target,
        options: .options(coverage: true, codeCoverageTargets: ["\(name)"])
      ),
      runAction: .runAction(configuration: target, executable: "\(name)"),
      archiveAction: .archiveAction(configuration: target),
      profileAction: .profileAction(configuration: target, executable: "\(name)"),
      analyzeAction: .analyzeAction(configuration: target)
    )
  }
}

public extension Scheme {
  static func scheme(name: String, environment: ConfigurationEnvironment) -> Scheme {
    let appName = Project.Environment.appName
    let schemeName = switch environment {
    case .prod: appName
    case .stage: "\(appName)-\(environment.name)"
    }

    return .scheme(
      name: schemeName,
      buildAction: .buildAction(targets: [.target(name)]),
      runAction: .runAction(configuration: .init(stringLiteral: environment.name), executable: "\(name)"),
      archiveAction: .archiveAction(configuration: .release),
      profileAction: .profileAction(configuration: .release, executable: "\(name)"),
      analyzeAction: .analyzeAction(configuration: .stage)
    )
  }
}
