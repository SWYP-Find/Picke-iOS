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
  case Attendance
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
  /// 앱 강제/권장 업데이트 판정.
  case AppUpdate
}

/// 앱 전역이 쓰는 최하위 기반 모듈. 도메인·서비스보다 아래에 있고 아무것도 의존하지 않는다.
public enum CoreFeatureModule: String, CaseIterable {
  /// 하위 Core 모듈과 공용 외부 라이브러리를 한 번에 노출하는 우산.
  case PickeThirdParty
  /// 표준 타입 확장 등 순수 유틸.
  case PickeCoreUtility
  /// 키체인 등 로컬 보관소.
  case PickeStorage
}

/// 외부 SDK·플랫폼 기능을 감싸는 서비스 모듈.
///
/// 도메인 규칙이 아니라 "무엇으로 구현하느냐"가 본질인 것들이다(광고 SDK, 분석 SDK,
/// 키체인, 디바이스 정보). 계약은 Interface 타깃에 두고 SDK 는 구현 타깃에만 링크해,
/// 화면이 SDK 를 끌고 오지 않게 한다.
public enum ServiceFeatureModule: String, CaseIterable {
  /// AdFit 배너·네이티브 + GoogleMobileAds 리워드.
  case Ad
  /// Mixpanel 이벤트 + Sentry 모니터링.
  case Analytics
  /// 디바이스 식별·플랫폼 정보.
  case Device
  /// AVFoundation 음원 재생.
  case AudioPlayer
}

public enum DataFeatureModule: String, CaseIterable {
  case AppUpdate
  case Attendance
  case Auth
  case Battle
  case Comment
  case Home
  case Notification
  case Perspective
  case Profile
  case Search
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

  static func ServiceFeature(_ module: ServiceFeatureModule) -> Self {
    .relativeToRoot("Projects/Service/\(module.rawValue)")
  }

  static func CoreFeature(_ module: CoreFeatureModule) -> Self {
    .relativeToRoot("Projects/Core/\(module.rawValue)")
  }

  /// 디자인 시스템은 단일 모듈이라 레이어 디렉토리가 곧 모듈 경로다.
  static var DesignSystem: Self {
    .relativeToRoot("Projects/DesignSystem")
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

  /// 최하위 기반 모듈. 단일 타깃 모듈(PickeThirdParty/PickeCoreUtility)은 kind 를 생략하고,
  /// 계약을 가르는 모듈(PickeStorage)만 `.interface` 를 지정한다.
  static func Core(_ module: CoreFeatureModule, _ kind: FeatureTargetKind? = nil) -> Self {
    let suffix = switch kind {
    case .interface: "Interface"
    case .testing: "Testing"
    case .implementation, nil: ""
    }
    return .project(target: "\(module.rawValue)\(suffix)", path: .CoreFeature(module))
  }

  /// 디자인 시스템(단일 타깃).
  static var DesignSystem: Self {
    .project(target: "PickeDesignKit", path: .DesignSystem)
  }

  /// SDK 래핑 서비스 모듈. 기본은 구현 타깃(`<Service>Service`).
  /// 화면은 `.interface` 만 의존해 SDK 를 링크하지 않는 것을 권장.
  static func Service(_ module: ServiceFeatureModule, _ kind: FeatureTargetKind = .implementation) -> Self {
    let suffix = switch kind {
    case .interface: "ServiceInterface"
    case .implementation: "Service"
    case .testing: "ServiceTesting"
    }
    return .project(target: "\(module.rawValue)\(suffix)", path: .ServiceFeature(module))
  }

  /// 서버 계약(베이스 URL·도메인 경로)만 담는 모듈. SDK 도 도메인 규칙도 링크하지 않는다.
  static var api: Self {
    .project(target: "API", path: .relativeToRoot("Projects/Service/API"))
  }

  /// 서버 요청 정의(TargetType)와 요청 DTO 를 담는 모듈.
  static var apiEndpoint: Self {
    .project(target: "APIEndpoint", path: .relativeToRoot("Projects/Service/APIEndpoint"))
  }

  /// SDK 래핑 서비스 구현을 묶어 제공하는 엄브렐러 모듈.
  static var serviceAssembly: Self {
    .project(target: "ServiceAssembly", path: .relativeToRoot("Projects/Service/ServiceAssembly"))
  }

  /// 최하위 기반 모듈 구현을 묶어 제공하는 엄브렐러 모듈.
  static var coreAssembly: Self {
    .project(target: "CoreAssembly", path: .relativeToRoot("Projects/Core/CoreAssembly"))
  }
}
