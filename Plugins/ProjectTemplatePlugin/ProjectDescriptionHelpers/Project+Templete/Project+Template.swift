//
//  Project+Template.swift
//  ProjectTemplatePlugin
//
//  모듈 하나를 구성하는 단일 진입점.
//  Interface·Testing·Demo·Tests 는 플래그로 켠다 — buildableFolders 는 폴더가 없으면
//  generate 가 깨지므로, 해당 폴더를 실제로 둔 모듈만 켠다.
//

import ProjectDescription

public extension Project {
  static func makeModule(
    name: String = Environment.appName,
    bundleId: String,
    platform _: Platform = .iOS,
    product: Product = .staticFramework,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    testDependencies: [ProjectDescription.TargetDependency] = [],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false,
    hasInterface: Bool = false,
    interfaceDependencies: [ProjectDescription.TargetDependency] = [],
    hasTesting: Bool = false,
    testingDependencies: [ProjectDescription.TargetDependency] = [],
    hasDemo: Bool = false,
    demoDependencies: [ProjectDescription.TargetDependency] = [],
    demoDisplayName: String? = nil
  ) -> Project {
    let interfaceTargetName = "\(name)Interface"
    let testingTargetName = "\(name)Testing"
    let demoTargetName = "\(name)Demo"

    var targets: [Target] = []

    if hasInterface {
      targets.append(.target(
        name: interfaceTargetName,
        destinations: destinations,
        product: product,
        bundleId: "\(bundleId).Interface",
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        buildableFolders: ["Interface"],
        dependencies: interfaceDependencies,
        settings: suppressWarningsSettings
      ))
    }

    targets.append(.target(
      name: name,
      destinations: destinations,
      product: product,
      bundleId: bundleId,
      deploymentTargets: deploymentTarget,
      infoPlist: infoPlist,
      buildableFolders: resources != nil ? ["Sources", "Resources"] : ["Sources"],
      entitlements: entitlements,
      scripts: scripts,
      dependencies: (hasInterface ? [.target(name: interfaceTargetName)] : []) + dependencies,
      settings: suppressWarningsSettings
    ))

    // Testing: Interface 를 구현한 목·픽스처. 테스트 타깃만 이걸 참조한다.
    if hasTesting {
      targets.append(.target(
        name: testingTargetName,
        destinations: destinations,
        product: product,
        bundleId: "\(bundleId).Testing",
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        buildableFolders: ["Testing"],
        dependencies: (hasInterface ? [.target(name: interfaceTargetName)] : [])
          + [.target(name: name)]
          + testingDependencies,
        settings: suppressWarningsSettings
      ))
    }

    // Demo: 앱 전체를 빌드하지 않고 모듈 하나만 시뮬레이터에서 확인하는 용도.
    if hasDemo {
      targets.append(.target(
        name: demoTargetName,
        destinations: destinations,
        product: .app,
        bundleId: "\(bundleId).Demo",
        deploymentTargets: deploymentTarget,
        infoPlist: .extendingDefault(with: [
          "UILaunchScreen": [:],
          "CFBundleDisplayName": .string(demoDisplayName ?? demoTargetName),
        ]),
        buildableFolders: ["Demo"],
        dependencies: [.target(name: name)] + demoDependencies,
        settings: suppressWarningsSettings
      ))
    }

    if hasTests {
      targets.append(makeTestsTarget(
        name: name,
        bundleId: bundleId,
        destinations: destinations,
        deploymentTarget: deploymentTarget,
        // Testing 이 있으면 테스트가 그 목을 그대로 쓴다.
        dependencies: [.target(name: name)]
          + testDependencies
          + (hasTesting ? [.target(name: testingTargetName)] : [])
      ))
    }

    var allSchemes = schemes
    if hasDemo {
      // Demo 가 있으면 자동 스킴이 구현·Demo 를 한 BuildAction 으로 묶으므로 직접 나눈 스킴만 쓴다.
      allSchemes.append(contentsOf: [
        .module(name: name, hasTests: hasTests),
        .demo(name: demoTargetName),
      ])
    }

    return Project(
      name: name,
      options: .options(
        automaticSchemesOptions: hasDemo ? .disabled : .enabled(codeCoverageEnabled: true),
        defaultKnownRegions: ["en", "ko"],
        developmentRegion: "ko"
      ),
      packages: packages,
      settings: settings.injectingModuleConfigurationsIfNeeded(),
      targets: targets,
      schemes: allSchemes,
      fileHeaderTemplate: .default
    )
  }

  static func makeAppModule(
    name: String = Environment.appName,
    bundleId: String,
    platform: Platform = .iOS,
    product: Product = .app,
    packages: [Package] = [],
    deploymentTarget: ProjectDescription.DeploymentTargets = Environment.deploymentTarget,
    destinations: ProjectDescription.Destinations = Environment.deploymentDestination,
    settings: ProjectDescription.Settings,
    scripts: [ProjectDescription.TargetScript] = [],
    dependencies: [ProjectDescription.TargetDependency] = [],
    sources: ProjectDescription.SourceFilesList = ["Sources/**"],
    resources: ProjectDescription.ResourceFileElements? = nil,
    infoPlist: ProjectDescription.InfoPlist = .default,
    entitlements: ProjectDescription.Entitlements? = nil,
    schemes: [ProjectDescription.Scheme] = [],
    hasTests: Bool = false
  ) -> Project {
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
