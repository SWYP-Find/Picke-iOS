//
//  TargetDependency+DomainData.swift
//  ProjectTemplatePlugin
//
//  Domain/Data feature 마이크로 모듈 의존성 경로 helper.
//  TargetDependency+Presentation 과 동일한 패턴을 Domain/Data 레이어에 복제한다.
//  기존 .Domain(implements:)/.Data(implements:)(ModulePath) 와 시그니처가 달라 공존한다.
//

import ProjectDescription

// MARK: - Domain feature

public extension ProjectDescription.Path {
  /// microModule 은 4타깃을 단일 Project(Projects/Domain/<F>) 로 구성하므로
  /// 의존성 경로는 항상 프로젝트 디렉터리를 가리키고, 타깃명만 kind 로 달라진다.
  static func Domain(_ module: DomainFeatureModule) -> Self {
    return .relativeToRoot("Projects/Domain/\(module.rawValue)")
  }
}

public extension TargetDependency {
  static func Domain(
    _ module: DomainFeatureModule,
    _ target: ModuleTarget = .implementation
  ) -> Self {
    let targetName = switch target {
    case .interface:
      "\(module.rawValue)DomainInterface"
    case .implementation:
      "\(module.rawValue)Domain"
    case .testing:
      "\(module.rawValue)DomainTesting"
    }

    return .project(target: targetName, path: .Domain(module))
  }
}

// MARK: - Data feature

public extension ProjectDescription.Path {
  static func Data(_ module: DataFeatureModule) -> Self {
    return .relativeToRoot("Projects/Data/\(module.rawValue)")
  }
}

public extension TargetDependency {
  static func Data(_ module: DataFeatureModule) -> Self {
    return .project(target: "\(module.rawValue)Data", path: .Data(module))
  }
}
