//
//  TargetDependency+Modules.swift
//  Plugins
//
//  레이어 의존성 DSL. 카탈로그가 경로를 들고 있어 여기서는 타깃만 가리킨다.
//  모듈이 Interface 타깃(`Project.makeModule(hasInterface: true)`)을 가지면
//  `.domain(.auth, .interface)` 처럼 어느 타깃에 의존할지 명시할 수 있다.
//  기본값은 레이어별로 다르다. Feature·Domain 은 모든 모듈이 Interface 를 갖춰
//  `.interface` 가 기본이고, 구현을 링크하는 조립 레이어만 `.implementation` 을 명시한다.
//  Core·Service·UI 는 아직 Interface 가 없는 모듈이 남아 `.implementation` 이 기본이다.
//

import Foundation
import ProjectDescription

// MARK: - ModuleTarget

/// 모듈 의존 시 어느 타깃을 가리킬지. 레이어 무관 공통 개념.
public enum ModuleTarget {
  case interface
  case implementation
  /// 마이크로피처 모듈이 만드는 "<name>Testing" 타깃.
  /// 테스트 더블·픽스처 전용이라 테스트 타깃(testDependencies)에서만 참조한다.
  case testing
}

extension TargetDependency {
  /// interface → "<name>Interface", implementation → "<name>", testing → "<name>Testing" 타깃.
  static func moduleDependency(name: String, path: Path, target: ModuleTarget) -> TargetDependency {
    switch target {
    case .interface:
      return .project(target: "\(name)Interface", path: path)
    case .implementation:
      return .project(target: name, path: path)
    case .testing:
      return .project(target: "\(name)Testing", path: path)
    }
  }
}

// MARK: - Layer DSL

public extension TargetDependency {
  /// 피처 의존성. 피처끼리는 상대의 Interface 에만 의존하고,
  /// 구현 연결은 조립 레이어(FeatureAssembly/App)에서만 `.implementation` 으로 명시한다.
  static func feature(_ module: FeatureModule, _ target: ModuleTarget = .interface) -> Self {
    return .moduleDependency(name: module.rawValue, path: module.path, target: target)
  }

  /// 모든 피처를 묶고 구현을 등록하는 엄브렐러 모듈 (App 진입점).
  static var featureAssembly: Self {
    return .project(target: "FeatureAssembly", path: .relativeToFeature("FeatureAssembly"))
  }

  static func core(_ module: CoreModule, _ target: ModuleTarget = .implementation) -> Self {
    return .moduleDependency(name: module.rawValue, path: module.path, target: target)
  }

  /// 최하위 기반 모듈 구현을 묶어 제공하는 엄브렐러 모듈.
  static var coreAssembly: Self {
    return .core(.assembly)
  }

  static func service(_ module: ServiceModule, _ target: ModuleTarget = .implementation) -> Self {
    return .moduleDependency(name: module.rawValue, path: module.path, target: target)
  }

  /// SDK 래핑 서비스 구현을 묶어 제공하는 엄브렐러 모듈.
  static var serviceAssembly: Self {
    return .service(.assembly)
  }

  static func domain(_ module: DomainModule, _ target: ModuleTarget = .interface) -> Self {
    return .moduleDependency(name: module.rawValue, path: module.path, target: target)
  }

  /// 도메인 구현을 런타임에 조립하는 App 진입 경계.
  /// 조립 모듈 자체는 Interface 타깃이 없어 구현을 직접 가리킨다.
  static var domainAssembly: Self {
    return .domain(.assembly, .implementation)
  }

  static func ui(_ module: UIModule, _ target: ModuleTarget = .implementation) -> Self {
    return .moduleDependency(name: module.rawValue, path: module.path, target: target)
  }
}
