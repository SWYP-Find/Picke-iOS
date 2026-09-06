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

// Network
public extension TargetDependency {
  static func network(implements module: ModulePath.Networks) -> Self {
    projectTarget(module.rawValue, path: .network(implementation: module))
  }
}

// Domain
public extension TargetDependency {
  static func domain(implements module: ModulePath.Domains) -> Self {
    projectTarget(module.rawValue, path: .domain(implementation: module))
  }

  /// 컨텍스트별 Domain 구현을 묶어 제공하는 엄브렐러 모듈.
  static var domainAssembly: Self {
    projectTarget("DomainAssembly", path: .relativeToRoot("Projects/Domain/DomainAssembly"))
  }
}

// Data
public extension TargetDependency {
  static func data(implements module: ModulePath.Datas) -> Self {
    projectTarget(module.rawValue, path: .data(implementation: module))
  }

  /// 컨텍스트별 Repository 구현을 묶어 제공하는 엄브렐러 모듈.
  static var dataAssembly: Self {
    projectTarget("DataAssembly", path: .relativeToRoot("Projects/Data/DataAssembly"))
  }
}
