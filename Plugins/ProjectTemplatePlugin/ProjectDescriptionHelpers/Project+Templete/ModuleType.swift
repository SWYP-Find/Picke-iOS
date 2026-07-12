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

public enum PresentationFeatureModule: String, CaseIterable {
  case Presentation
  case Splash
  case Auth
  case Home
  case Chat
  case Hifi
  case Web
  case Battle
  case Profile
  case Notification
}

public enum ModuleType {
  case app
  case feature(PresentationFeatureModule)
  case module(name: String)
  /// Data/Domain 등 비-Presentation 모듈을 마이크로피처(Interface/구현/Testing/Tests) 4타깃으로 구성.
  case microModule(name: String)
}
