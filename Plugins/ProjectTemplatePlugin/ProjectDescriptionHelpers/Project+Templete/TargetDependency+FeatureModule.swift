//
//  TargetDependency+FeatureModule.swift
//  ProjectTemplatePlugin
//
//  feature 단위로 분리된 Domain/Data 마이크로 모듈 접근자.
//  기존 `.Domain(implements:)` / `.Data(implements:)`(레이어 단위) 와 시그니처가 달라 공존한다.
//

import ProjectDescription

public enum DomainFeatureModule: String, CaseIterable {
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
  case Common
}

public enum DataFeatureModule: String, CaseIterable {
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
  case Common
}

public extension ProjectDescription.Path {
  static func Domain(_ module: DomainFeatureModule, _: ModuleTarget = .implementation) -> Self {
    .relativeToRoot("Projects/Domain/\(module.rawValue)")
  }

  static func Data(_ module: DataFeatureModule) -> Self {
    .relativeToRoot("Projects/Data/\(module.rawValue)")
  }
}

public extension TargetDependency {
  /// `<Feature>DomainInterface` / `<Feature>Domain` / `<Feature>DomainTesting` 타깃 참조.
  static func Domain(_ module: DomainFeatureModule, _ kind: ModuleTarget = .implementation) -> Self {
    let suffix = switch kind {
    case .interface: "Interface"
    case .implementation: ""
    case .testing: "Testing"
    }
    return .project(target: "\(module.rawValue)Domain\(suffix)", path: .Domain(module, kind))
  }

  /// `<Feature>Data` 단일 타깃 참조.
  static func Data(_ module: DataFeatureModule) -> Self {
    .project(target: "\(module.rawValue)Data", path: .Data(module))
  }
}
