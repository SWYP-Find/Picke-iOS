//
//  TargetDependency+DataFeature.swift
//  ProjectTemplatePlugin
//
//  Data feature 모듈(<Feature>Data) 의존성 경로 helper.
//  Project.configure(.module(name: "<Feature>Data")) 로 생성한 모듈을 참조한다.
//

import ProjectDescription

public enum DataFeatureModule: String, CaseIterable {
  case Search
}

public extension TargetDependency {
  static func Data(_ module: DataFeatureModule) -> Self {
    return .project(
      target: "\(module.rawValue)Data",
      path: .relativeToRoot("Projects/Data/\(module.rawValue)")
    )
  }
}
