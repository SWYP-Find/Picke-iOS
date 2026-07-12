//
//  TargetDependency+DomainFeature.swift
//  ProjectTemplatePlugin
//
//  Domain feature 마이크로모듈(<Feature>Domain) 의존성 경로 helper.
//  Project.configure(.microModule(name: "<Feature>Domain")) 로 생성한 모듈을 참조한다.
//

import ProjectDescription

public enum DomainFeatureModule: String, CaseIterable {
  case Search
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

    return .project(
      target: targetName,
      path: .relativeToRoot("Projects/Domain/\(module.rawValue)")
    )
  }
}
