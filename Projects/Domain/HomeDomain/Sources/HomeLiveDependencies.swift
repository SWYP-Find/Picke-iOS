//
//  HomeLiveDependencies.swift
//  HomeDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import HomeDomainInterface
import ComposableArchitecture

extension HomeUseCaseDependency: DependencyKey {
  public static var liveValue: HomeInterface { HomeUseCaseImpl() }
}
