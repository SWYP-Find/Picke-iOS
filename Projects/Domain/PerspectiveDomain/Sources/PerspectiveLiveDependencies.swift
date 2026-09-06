//
//  PerspectiveLiveDependencies.swift
//  PerspectiveDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import PerspectiveDomainInterface
import ComposableArchitecture

extension PerspectiveUseCaseDependency: DependencyKey {
  public static var liveValue: PerspectiveInterface { PerspectiveUseCaseImpl() }
}

extension PerspectiveRepositoryDependency: DependencyKey {
  public static var liveValue: PerspectiveInterface { PerspectiveRepositoryImpl() }
}
