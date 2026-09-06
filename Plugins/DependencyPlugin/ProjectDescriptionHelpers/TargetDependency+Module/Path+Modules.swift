//
//  Path+Modules.swift
//  Plugins
//
//  Created by 서원지 on 2/21/24.
//

import Foundation
import ProjectDescription

// MARK: - Network
public extension ProjectDescription.Path {
  static var networking: Self {
    return .relativeToRoot("Projects/\(ModulePath.Networks.name)")
  }
  
  static func network(implementation module: ModulePath.Networks) -> Self {
    return .relativeToRoot("Projects/\(ModulePath.Networks.name)/\(module.rawValue)")
  }
}

// MARK: - Domain
public extension ProjectDescription.Path {
  static var domain: Self {
    return .relativeToRoot("Projects/\(ModulePath.Domains.name)")
  }

  static func domain(implementation module: ModulePath.Domains) -> Self {
    return .relativeToRoot("Projects/\(ModulePath.Domains.name)/\(module.rawValue)")
  }
}

// MARK: - Data
public extension ProjectDescription.Path {
  static var data: Self {
    return .relativeToRoot("Projects/\(ModulePath.Datas.name)")
  }

  static func data(implementation module: ModulePath.Datas) -> Self {
    return .relativeToRoot("Projects/\(ModulePath.Datas.name)/\(module.rawValue)")
  }
}
