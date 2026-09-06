//
//  TargetDependency+Feature.swift
//  ProjectTemplatePlugin
//
//  Feature 레이어 의존성 경로 helper.
//  Project.configure(.feature(...)) 와 같은 FeatureModule catalog 를 사용한다.
//

import ProjectDescription

public extension ProjectDescription.Path {
  static var Feature: Self {
    return .relativeToRoot("Projects/Feature")
  }

  static func Feature(implementation module: FeatureModule) -> Self {
    return .relativeToRoot("Projects/Feature/\(module.rawValue)")
  }

  static func Feature(
    _ module: FeatureModule,
    _ target: ModuleTarget
  ) -> Self {
    switch target {
    case .interface:
      return .relativeToRoot("Projects/Feature/\(module.rawValue)/Interface")
    case .implementation:
      return .Feature(implementation: module)
    case .testing:
      return .relativeToRoot("Projects/Feature/\(module.rawValue)/Testing")
    }
  }
}

public extension TargetDependency {
  /// 피처 의존성. 피처끼리는 상대의 Interface 에만 의존하고,
  /// 구현 연결은 조립 레이어(FeatureAssembly/App)에서만 `.implementation` 으로 명시한다.
  static func feature(
    _ module: FeatureModule,
    _ target: ModuleTarget = .interface
  ) -> Self {
    let targetName = switch target {
    case .interface:
      "\(module.rawValue)Interface"
    case .implementation:
      module.rawValue
    case .testing:
      "\(module.rawValue)Testing"
    }

    return .project(target: targetName, path: .Feature(module, target))
  }

  static func feature(implements module: FeatureModule) -> Self {
    return .feature(module, .implementation)
  }

  /// 모든 피처를 묶고 구현을 등록하는 엄브렐러 모듈 (App 진입점).
  static var featureAssembly: Self {
    return .project(
      target: "FeatureAssembly",
      path: .relativeToRoot("Projects/Feature/FeatureAssembly")
    )
  }
}
