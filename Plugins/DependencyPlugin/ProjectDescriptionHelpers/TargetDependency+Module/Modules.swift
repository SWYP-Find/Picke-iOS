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
  enum Datas: String, CaseIterable {
    case Model
    case Data
    case Repository
    case API
    case Remote
    case DataTesting

    public static let name: String = "Data"
  }
}

// MARK: -  CoreMoudule

public extension ModulePath {
  enum Domains: String, CaseIterable {
    case Domain
    case DomainTesting

    public static let name: String = "Domain"
  }
}
