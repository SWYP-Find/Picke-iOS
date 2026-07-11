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
  case MainTab
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
}
