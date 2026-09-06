//
//  AppUpdateLiveDependencies.swift
//  AppUpdateDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AppUpdateDomainInterface
import ComposableArchitecture

extension AppUpdateUseCaseDependency: DependencyKey {
  public static var liveValue: AppUpdateUseCaseInterface { AppUpdateUseCaseImpl() }
}
