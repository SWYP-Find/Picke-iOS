//
//  ConfigurationEnvironment.swift
//  DependencyPackagePlugin
//
//  Created by Wonji Suh  on 7/31/25.
//

import Foundation
import ProjectDescription

public enum ConfigurationEnvironment: CaseIterable {
  case stage, prod

  public var name: String {
    switch self {
    case .stage: "Stage"
    case .prod: "Prod"
    }
  }

  /// 스킴 액션에서 쓰는 ConfigurationName
  public var configurationName: ConfigurationName {
    .init(stringLiteral: name)
  }

  /// 빌드 최적화 레벨 매핑 (Stage 는 debug 타입 컨피그)
  public var buildOptimization: ConfigurationName {
    switch self {
    case .stage: .debug
    case .prod: .release
    }
  }
}
