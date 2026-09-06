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

