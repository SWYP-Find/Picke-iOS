//
//  DeviceRepositoryDependency+Live.swift
//  DeviceService
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import DeviceServiceInterface

// MARK: - Live

extension DeviceRepositoryDependency: DependencyKey {
  public static var liveValue: DeviceInterface { DeviceRepositoryImpl() }
}
