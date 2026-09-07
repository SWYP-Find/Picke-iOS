//
//  ServiceDependencyAssembly.swift
//  ServiceAssembly
//

import CoreAssembly
import PickeAuthInterface
import PickeNetworkInterface
import PickeStorageInterface

import Dependencies

public enum ServiceDependencyAssembly {
  public static func register(into values: inout DependencyValues) {
    values.registerLiveServices()
  }
}

public extension DependencyValues {
  mutating func registerLiveServices() {
    StorageAssembly.register(into: &self)
    networkClient = NetworkContainer.authenticatedClient
    authService = NetworkContainer.authService
  }
}
