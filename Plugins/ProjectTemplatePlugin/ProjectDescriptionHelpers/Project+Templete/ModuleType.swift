//
//  ModuleType.swift
//  ProjectTemplatePlugin
//
//  Project.configure 의 진입 분기 타입.
//

import ProjectDescription

public enum ModuleTarget {
  case interface
  case implementation
  case testing
}

/// Feature 레이어 모듈 카탈로그(단일 출처).
/// 모듈 추가 = case 한 줄. rawValue 가 실제 타깃명이라 오타로 깨지지 않는다.
/// 엄브렐러 모듈(FeatureAssembly)은 피처가 아니므로 여기 넣지 않는다.
public enum FeatureModule: String, CaseIterable {
  case splash = "Splash"
  case auth = "Auth"
  case home = "Home"
  case chat = "Chat"
  case hifi = "Hifi"
  case web = "Web"
  case battle = "Battle"
  case profile = "Profile"
  case notification = "Notification"
}

public enum ModuleType {
  case app
  case feature(FeatureModule)
  case module(name: String)
  /// Data/Domain 등 비-Feature 모듈을 마이크로피처(Interface/구현/Testing/Tests) 4타깃으로 구성.
  case microModule(name: String)
}
