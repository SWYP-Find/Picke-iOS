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
