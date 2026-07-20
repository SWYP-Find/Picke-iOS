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
  case Shared(Shareds)
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
  enum Datas: String, CaseIterable {
    case Model
    case Data
    case Repository
    case API
    case Service
    case DataTesting

    public static let name: String = "Data"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  enum Domains: String, CaseIterable {
    case Entity
    case UseCase
    case Domain
    case DomainInterface
    case DomainTesting

    public static let name: String = "Domain"
  }
}

public extension ModulePath {
  enum Shareds: String, CaseIterable {
    case Shared
    case PickeDesignKit
    case Utill
    /// 광고 SDK(AdFit) 전용 모듈. 디자인 시스템과 분리해, 광고를 노출하는 화면만 명시적으로 의존한다.
    case AdKit

    public static let name: String = "Shared"
    case ThirdParty
  }
}
