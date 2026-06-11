//
//  DevicePlatform.swift
//  Entity
//
//  FCM 디바이스 등록 플랫폼 — POST /api/v1/devices `platform`.
//

import Foundation

public enum DevicePlatform: String, Equatable, Sendable {
  case ios = "IOS"
  case android = "ANDROID"
}
