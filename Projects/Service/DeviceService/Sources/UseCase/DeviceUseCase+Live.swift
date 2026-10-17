//
//  DeviceUseCase+Live.swift
//  DeviceService
//
//  Created by Picke on 10/11/26.
//

import Foundation

import ComposableArchitecture
import DeviceServiceInterface

// MARK: - Live

extension DeviceUseCaseImpl: DependencyKey {
  public static var liveValue = DeviceUseCaseImpl()
}
