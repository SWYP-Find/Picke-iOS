//
//  Project+Template.swift
//  MyPlugin
//
//  Created by 서원지 on 1/6/24.
//

import ProjectDescription

// MARK: - Suppress Warnings Setting

private let suppressWarningsSettings: ProjectDescription.Settings = .settings(
  base: [
    "OTHER_SWIFT_FLAGS": "$(inherited) -suppress-warnings",
    // Xcode 16 Explicitly Built Modules 비활성화.
    // (system 모듈(os_object)/WebKit pcm emit 실패 및 "implicit use of module files is disabled" 에러 회피)
    "SWIFT_ENABLE_EXPLICIT_MODULES": "NO",
    "_EXPERIMENTAL_SWIFT_EXPLICIT_MODULES": "NO",
    "CLANG_ENABLE_EXPLICIT_MODULES": "NO",
  ]
)

public enum PresentationFeatureModule: String, CaseIterable {
  case Splash
  case Auth
  case MainTab
  case Home
  case Chat
  case Hifi
  case Web
  case Battle
  case Profile
  case Notification
}

public enum ModuleType {
  case app
  case feature(PresentationFeatureModule)
  case module(name: String)
}

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
    hasTests: Bool = false
  ) -> Project {
    switch moduleType {
    case .app:
      return makeAppModule(
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
      return makeModule(
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
    case let .feature(module):
      return makeMicroFeature(
        name: module.rawValue,
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

  static func makeAppModule(
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
    hasTests: Bool = false
  ) -> Project {
    let appTarget: Target = .target(
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

    // 환경(dev/stage/prod)은 build configuration(xcconfig)으로 갈리므로 타깃은 1개면 충분하다.
    // (과거엔 이름만 다른 동일 타깃을 4개 만들어 스킴/타깃이 중복 노출됐다.)
    var targets: [Target] = [appTarget]

    if hasTests {
      let appTestTarget: Target = .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundleId).\(name)Tests",
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        sources: ["Tests/Sources/**"],
        dependencies: [.target(name: name)],
        settings: suppressWarningsSettings
      )
      targets.append(appTestTarget)
    }

    return Project(
      name: name,
      options: .options(
        defaultKnownRegions: ["en", "ko"],
        developmentRegion: "ko"
      ),
      packages: packages,
      settings: settings,
      targets: targets,
      schemes: schemes
    )
  }

  static func makeModule(
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
    hasTests: Bool = false
  ) -> Project {
    let appTarget: Target = .target(
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

    var targets: [Target] = [appTarget]

    if hasTests {
      let appTestTarget: Target = .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundleId).\(name)Tests",
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        sources: ["Tests/Sources/**"],
        dependencies: [.target(name: name)],
        settings: suppressWarningsSettings
      )
      targets.append(appTestTarget)
    }

    return Project(
      name: name,
      packages: packages,
      settings: settings,
      targets: targets,
      schemes: schemes
    )
  }

  static func makeMicroFeature(
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
      sources: ["Interface/Sources/**"],
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
      sources: ["Sources/**"],
      resources: resources,
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
      sources: ["Testing/Sources/**"],
      dependencies: [
        .target(name: interfaceTargetName),
        .target(name: name),
      ] + testingDependencies,
      settings: suppressWarningsSettings
    )

    let testTarget: Target = .target(
      name: "\(name)Tests",
      destinations: destinations,
      product: .unitTests,
      bundleId: "\(bundleId).Tests",
      deploymentTargets: deploymentTarget,
      infoPlist: .default,
      sources: ["Tests/Sources/**"],
      dependencies: [
        .target(name: name),
        .target(name: testingTargetName),
      ],
      settings: suppressWarningsSettings
    )

    return Project(
      name: name,
      settings: settings,
      targets: [
        interfaceTarget,
        featureTarget,
        testingTarget,
        testTarget,
      ],
      schemes: schemes
    )
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
      runAction: .runAction(configuration: target),
      archiveAction: .archiveAction(configuration: target),
      profileAction: .profileAction(configuration: target),
      analyzeAction: .analyzeAction(configuration: target)
    )
  }
}

public extension Scheme {
  static func scheme(name: String, environment: ConfigurationEnvironment) -> Scheme {
    let appName = Project.Environment.appName
    let schemeName = switch environment {
    case .prod: appName
    case .dev, .stage: "\(appName)-\(environment.name)"
    }

    return .scheme(
      name: schemeName,
      buildAction: .buildAction(targets: [.target(name)]),
      runAction: .runAction(configuration: .init(stringLiteral: environment.name)),
      archiveAction: .archiveAction(configuration: .release),
      profileAction: .profileAction(configuration: .release),
      analyzeAction: .analyzeAction(configuration: .debug)
    )
  }
}
