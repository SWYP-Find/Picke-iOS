//
//  Project+App.swift
//  ProjectTemplatePlugin
//
//  app 모듈 타입의 Project 구성.
//

import ProjectDescription

extension Project {
  static func configureApp(
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
    // 과거엔 이름만 다른 동일 타깃을 4개 만들어 스킴/타깃이 중복 노출됐다.
    var targets: [Target] = [appTarget]

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
}
