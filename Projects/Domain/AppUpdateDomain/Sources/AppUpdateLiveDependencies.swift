//
//  AppUpdateLiveDependencies.swift
//  AppUpdateDomain
//
//  Created by Picke on 10/11/26.
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AppUpdateDomainInterface
import ComposableArchitecture

extension AppUpdateUseCaseDependency: DependencyKey {
  public static var liveValue: AppUpdateUseCaseInterface { AppUpdateUseCaseImpl() }
}

extension AppUpdateRepositoryDependency: DependencyKey {
  public static var liveValue: AppUpdateInterface { AppUpdateRepositoryImpl() }
}
