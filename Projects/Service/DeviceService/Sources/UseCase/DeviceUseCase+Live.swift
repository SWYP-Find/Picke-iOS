//
//  DeviceUseCase+Live.swift
//  DeviceService
//

import Foundation

import ComposableArchitecture
import DeviceServiceInterface

// MARK: - Live

extension DeviceUseCaseImpl: DependencyKey {
  public static var liveValue = DeviceUseCaseImpl()
}
