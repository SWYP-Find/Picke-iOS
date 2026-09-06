//
//  Modules.swift
//  Plugins
//
//  Created by 서원지 on 2/21/24.
//

import Foundation
import ProjectDescription

public enum ModulePath {
  case Network(Networks)
  case Domain(Domains)
  case Data(Datas)
}

// MARK: -  CoreDomainModule

public extension ModulePath {
  enum Networks: String, CaseIterable {
    case NetworkModule
    case Networking
    case NetworkToken
    case NetworkHeader
    case ThirdPartys

    public static let name: String = "Network"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  /// 엄브렐러(DataAssembly)는 모듈이 아니라 조립 경계라 카탈로그에 넣지 않는다.
  /// `TargetDependency.dataAssembly` 로만 접근한다.
  enum Datas: String, CaseIterable {
    case Model
    case DataTesting

    public static let name: String = "Data"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  /// 엄브렐러(DomainAssembly)는 모듈이 아니라 조립 경계라 카탈로그에 넣지 않는다.
  /// `TargetDependency.domainAssembly` 로만 접근한다.
  enum Domains: String, CaseIterable {
    case DomainTesting

    public static let name: String = "Domain"
  }
}
