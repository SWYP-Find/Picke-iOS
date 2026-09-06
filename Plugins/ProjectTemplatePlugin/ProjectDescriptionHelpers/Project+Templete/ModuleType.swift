//
//  ModuleType.swift
//  ProjectTemplatePlugin
//
//  Project.configure 의 진입 분기 타입.
//  어떤 모듈이 있는지(카탈로그)는 DependencyPlugin 의 Modules.swift 가 단일 출처다.
//

import ProjectDescription

public enum ModuleType {
  case app
  /// 단일 타깃 모듈.
  case module(name: String)
  /// Interface / 구현 / Testing / Tests 4타깃 마이크로피처 모듈.
  case microModule(name: String)
}
