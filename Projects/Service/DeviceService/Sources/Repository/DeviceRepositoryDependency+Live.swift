//
//  DeviceRepositoryDependency+Live.swift
//  DeviceService
//

import ComposableArchitecture
import DeviceServiceInterface

// MARK: - Live

extension DeviceRepositoryDependency: DependencyKey {
  public static var liveValue: DeviceInterface { DeviceRepositoryImpl() }
}
