//
//  Modules.swift
//  Plugins
//
//  Created by 서원지 on 2/21/24.
//

import Foundation
import ProjectDescription

public enum ModulePath {
  case network(Networks)
  case domain(Domains)
  case data(Datas)
}

// MARK: -  CoreDomainModule

public extension ModulePath {
  enum Networks: String, CaseIterable {
    case networkModule = "NetworkModule"
    case networking = "Networking"
    case networkToken = "NetworkToken"
    case networkHeader = "NetworkHeader"
    case thirdPartys = "ThirdPartys"

    public static let name: String = "Network"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  /// 엄브렐러(DataAssembly)는 모듈이 아니라 조립 경계라 카탈로그에 넣지 않는다.
  /// `TargetDependency.dataAssembly` 로만 접근한다.
  enum Datas: String, CaseIterable {
    case model = "Model"
    case dataTesting = "DataTesting"

    public static let name: String = "Data"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  /// 엄브렐러(DomainAssembly)는 모듈이 아니라 조립 경계라 카탈로그에 넣지 않는다.
  /// `TargetDependency.domainAssembly` 로만 접근한다.
  enum Domains: String, CaseIterable {
    case domainTesting = "DomainTesting"

    public static let name: String = "Domain"
  }
}
