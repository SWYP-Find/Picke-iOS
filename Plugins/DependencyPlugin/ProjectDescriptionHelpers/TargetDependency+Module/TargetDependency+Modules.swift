//
//  TargetDependency+Modules.swift
//  Plugins
//
//  Created by 서원지 on 2/21/24.
//

import Foundation
import ProjectDescription

// 공통 헬퍼
private extension TargetDependency {
  static func projectTarget(_ name: String, path: ProjectDescription.Path) -> Self {
    .project(target: name, path: path)
  }
}

// Presentation
public extension TargetDependency {
  static func Presentation(
    _ module: ModulePath.Presentations,
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

    return projectTarget(targetName, path: .Presentation(module, target))
  }

  static func Presentation(implements module: ModulePath.Presentations) -> Self {
    Presentation(module, .implementation)
  }
}

// Shared
public extension TargetDependency {
  static func Shared(implements module: ModulePath.Shareds) -> Self {
    projectTarget(module.rawValue, path: .Shared(implementation: module))
  }
}


// Network
public extension TargetDependency {
  static func Network(implements module: ModulePath.Networks) -> Self {
    projectTarget(module.rawValue, path: .Network(implementation: module))
  }
}


// Domain
public extension TargetDependency {
  static func Domain(implements module: ModulePath.Domains) -> Self {
    projectTarget(module.rawValue, path: .Domain(implementation: module))
  }
}

// Data
public extension TargetDependency {
  static func Data(implements module: ModulePath.Datas) -> Self {
    projectTarget(module.rawValue, path: .Data(implementation: module))
  }
}
