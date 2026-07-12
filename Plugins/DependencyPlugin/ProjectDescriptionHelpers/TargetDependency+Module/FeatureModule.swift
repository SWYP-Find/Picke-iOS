//
//  FeatureModule.swift
//  Plugins
//
//  Domain·Data 레이어를 Presentation 처럼 feature별 마이크로 모듈로 재편하기 위한
//  접근자. 기존 레이어 단일 모듈 접근자(`.Domain(implements:)` / `.Data(implements:)`)와
//  시그니처가 달라 마이그레이션 기간 동안 공존한다.
//
//  - Domain feature: `Projects/Domain/<Feature>` 의 마이크로피처 4타깃
//    (`<Feature>DomainInterface` / `<Feature>Domain` / `<Feature>DomainTesting` / Tests)
//  - Data feature: `Projects/Data/<Feature>` 의 단일 타깃 `<Feature>Data`
//

import Foundation
import ProjectDescription

// MARK: - Feature 모듈 식별자

public enum DomainFeatureModule: String, CaseIterable {
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
  /// 여러 feature 가 공유하는 저변경 횡단 계약(AppUpdate/Analytics/Device 등)
  case Common
}

public enum DataFeatureModule: String, CaseIterable {
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
  case Common
}

/// Domain feature 모듈 내 대상 타깃 종류.
public enum FeatureTargetKind {
  case interface
  case implementation
  case testing
}

// MARK: - Path

public extension ProjectDescription.Path {
  static func DomainFeature(_ module: DomainFeatureModule) -> Self {
    .relativeToRoot("Projects/Domain/\(module.rawValue)")
  }

  static func DataFeature(_ module: DataFeatureModule) -> Self {
    .relativeToRoot("Projects/Data/\(module.rawValue)")
  }
}

// MARK: - TargetDependency

public extension TargetDependency {
  /// feature별 Domain 모듈. 기본은 구현 타깃(`<Feature>Domain`).
  /// Data·Presentation 은 컴파일 격리를 위해 `.interface` 만 의존하는 것을 권장.
  static func Domain(_ module: DomainFeatureModule, _ kind: FeatureTargetKind = .implementation) -> Self {
    let suffix = switch kind {
    case .interface: "DomainInterface"
    case .implementation: "Domain"
    case .testing: "DomainTesting"
    }
    return .project(target: "\(module.rawValue)\(suffix)", path: .DomainFeature(module))
  }

  /// feature별 Data 모듈(단일 타깃 `<Feature>Data`).
  static func Data(_ module: DataFeatureModule) -> Self {
    .project(target: "\(module.rawValue)Data", path: .DataFeature(module))
  }
}
