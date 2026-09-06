//
//  Path+Modules.swift
//  Plugins
//
//  레이어 루트 경로. 카탈로그가 rawValue 만 넘겨 재사용한다.
//

import Foundation
import ProjectDescription

public extension ProjectDescription.Path {
  static func relativeToFeature(_ name: String) -> Self {
    return .relativeToRoot("Projects/Feature/\(name)")
  }

  static func relativeToCore(_ name: String) -> Self {
    return .relativeToRoot("Projects/Core/\(name)")
  }


  static func relativeToService(_ name: String) -> Self {
    return .relativeToRoot("Projects/Service/\(name)")
  }

  static func relativeToDomain(_ name: String) -> Self {
    return .relativeToRoot("Projects/Domain/\(name)")
  }

  /// 디자인 시스템은 아직 단일 모듈이라 레이어 디렉토리가 곧 모듈 경로다.
  static var designSystem: Self {
    return .relativeToRoot("Projects/DesignSystem")
  }

}
