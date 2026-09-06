//
//  AppUpdateLiveDependencies.swift
//  AppUpdateData
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AppUpdateDomainInterface
import ComposableArchitecture

extension AppUpdateRepositoryDependency: DependencyKey {
  public static var liveValue: AppUpdateInterface { AppUpdateRepositoryImpl() }
}
