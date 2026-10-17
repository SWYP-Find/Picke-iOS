//
//  Project.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import DependencyPackagePlugin
import DependencyPlugin
import ProjectDescription
import ProjectTemplatePlugin

private let appName = Project.Environment.appName
private let auditEnabled = Environment.classUIAudit.getBoolean(default: false)
private let appDependencies: [TargetDependency] = [
  // 화면·도메인·데이터 구현은 각 레이어의 조립 경계 하나로 들어온다.
  .featureAssembly,
  .domainAssembly,
  .serviceAssembly,
  .core(.storage, .interface),
  .service(.config),
  .ui(.animation),
  .SPM.googleMobileAds,
  .SPM.kingfisher,
]

let project = Project.makeAppModule(
  name: appName,
  bundleId: .mainBundleID(),
  product: .app,
  settings: .appMainSetting,
  scripts: [.SentryUploadString],
  dependencies: appDependencies,
  testDependencies: [.SPM.issueReportingTestSupport],
  resources: ["Resources/**"],
  infoPlist: .appInfoPlist,
  entitlements: .file(path: "../../Entitlements/Picke.entitlements"),
  schemes: Scheme.appSchemes(appName: appName) + (auditEnabled ? [auditScheme] : []),
  hasTests: true,
  additionalTargets: auditEnabled ? auditTargets() : []
)

// 일반 앱 생성에서는 검증 전용 소스와 타깃을 제외한다.
private func auditTargets() -> [Target] {
  let host = Target.target(
    name: "PickeClassAuditHost",
    destinations: Project.Environment.deploymentDestination,
    product: .app,
    productName: "PickeClassAuditHost",
    bundleId: "com.picke.class-audit",
    deploymentTargets: Project.Environment.deploymentTarget,
    infoPlist: .appInfoPlist,
    sources: [
      .glob("Sources/**", excluding: ["Sources/Application/PickeApp.swift"]),
      "AuditHost/Sources/**",
    ],
    resources: ["Resources/**"],
    dependencies: appDependencies,
    settings: auditSettings(
      name: "PickeClassAuditHost",
      bundleID: "com.picke.class-audit"
    )
  )
  var testsSettings = auditSettings(
    name: "PickeClassUITests",
    bundleID: "com.picke.class-audit.uitests"
  )
  testsSettings.base["TEST_TARGET_NAME"] = "PickeClassAuditHost"
  // UI 테스트는 별도 프로세스에서 실행하므로 앱 전용 SDK를 링크하지 않는다.
  testsSettings.base["OTHER_LDFLAGS"] = ""
  let tests = Target.target(
    name: "PickeClassUITests",
    destinations: host.destinations,
    product: .uiTests,
    bundleId: "com.picke.class-audit.uitests",
    deploymentTargets: host.deploymentTargets,
    infoPlist: .default,
    sources: ["UITests/Sources/**"],
    dependencies: [.target(name: host.name)],
    settings: testsSettings
  )
  return [host, tests]
}

private func auditSettings(
  name: String,
  bundleID: String
) -> Settings {
  var settings = suppressWarningsSettings
  settings.base["PRODUCT_NAME"] = .string(name)
  settings.base["PRODUCT_MODULE_NAME"] = .string(name)
  settings.base["PRODUCT_BUNDLE_IDENTIFIER"] = .string(bundleID)
  settings.base["BUNDLE_DISPLAY_NAME"] = "Class Audit"
  return settings
}

private var auditScheme: Scheme {
  .scheme(
    name: "Picke-ClassUIAudit",
    shared: true,
    buildAction: .buildAction(targets: ["PickeClassAuditHost"]),
    testAction: .targets(["PickeClassUITests"], configuration: .release),
    runAction: .runAction(configuration: .release, executable: "PickeClassAuditHost")
  )
}
