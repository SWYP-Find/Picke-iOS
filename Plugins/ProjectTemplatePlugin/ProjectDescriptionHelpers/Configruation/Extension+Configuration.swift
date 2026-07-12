//
//  Extension+Configuration.swift
//  DependencyPackagePlugin
//
//  Created by Wonji Suh  on 7/31/25.
//

import Foundation
import ProjectDescription

public extension ConfigurationName {
  static let stage = ConfigurationName.configuration(ConfigurationEnvironment.stage.name)
  static let prod = ConfigurationName.configuration(ConfigurationEnvironment.prod.name)
}

public extension [Configuration] {
  /// 빌드 컨피그 단일 출처. Stage 는 debug 타입(Dev/Debug 제거).
  static let `default`: [Configuration] = [
    .debug(name: .stage, xcconfig: .path(.stage)),
    .release(name: .prod, xcconfig: .path(.prod)),
    .release(name: .release, xcconfig: .path(.release)),
  ]

  /// 1차 파티 모듈/피처용 컨피그(이름·빌드타입만, 앱 xcconfig 미주입).
  /// 앱·외부 SPM 패키지와 컨피그 "이름"을 일치시켜 Stage 빌드 산출물이 모두
  /// Stage-iphonesimulator 로 모이게 한다. 없으면 외부 패키지는 Stage 로, 모듈은
  /// fallback 컨피그로 갈려 "no such module" / 번들 lstat 실패가 난다.
  static let moduleConfigurations: [Configuration] = [
    .debug(name: .stage),
    .release(name: .prod),
    .release(name: .release),
  ]
}

public extension Settings {
  /// 모듈/피처 프로젝트에 공통 컨피그([Stage/Prod/Release])를 주입해 재구성한다.
  /// 모듈은 `.settings()` 로 컨피그를 비워 넘기므로, 기존 base/defaultSettings 는 보존하고
  /// configurations 만 채워 앱·외부 패키지와 컨피그 이름을 일치시킨다.
  func injectingModuleConfigurationsIfNeeded() -> Settings {
    .settings(
      base: base,
      configurations: .moduleConfigurations,
      defaultSettings: defaultSettings
    )
  }
}

public extension ProjectDescription.Path {
  static func path(_ configuration: ConfigurationName) -> Self {
    return .relativeToRoot("Config/\(configuration.rawValue).xcconfig")
  }
}
