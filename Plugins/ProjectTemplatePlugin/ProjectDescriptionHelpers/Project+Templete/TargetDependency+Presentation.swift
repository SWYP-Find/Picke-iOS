//
//  TargetDependency+Presentation.swift
//  ProjectTemplatePlugin
//
//  Presentation micro-feature 의존성 경로 helper.
//  Project.configure(.feature(...)) 와 같은 PresentationFeatureModule catalog 를 사용한다.
//

import ProjectDescription

public extension ProjectDescription.Path {
  static var Presentation: Self {
    return .relativeToRoot("Projects/Presentation")
  }

  static func Presentation(implementation module: PresentationFeatureModule) -> Self {
    return .relativeToRoot("Projects/Presentation/\(module.rawValue)")
  }

  static func Presentation(
    _ module: PresentationFeatureModule,
    _ target: ModuleTarget
  ) -> Self {
    switch target {
    case .interface:
      return .relativeToRoot("Projects/Presentation/\(module.rawValue)/Interface")
    case .implementation:
      return .Presentation(implementation: module)
    case .testing:
      return .relativeToRoot("Projects/Presentation/\(module.rawValue)/Testing")
    }
  }
}

public extension TargetDependency {
  static func Presentation(
    _ module: PresentationFeatureModule,
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

    return .project(target: targetName, path: .Presentation(module, target))
  }

  static func Presentation(implements module: PresentationFeatureModule) -> Self {
    return .Presentation(module, .implementation)
  }
}
