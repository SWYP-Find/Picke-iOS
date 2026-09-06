//
//  BattleLiveDependencies.swift
//  BattleDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import BattleDomainInterface
import ComposableArchitecture

extension BattleUseCaseDependency: DependencyKey {
  public static var liveValue: BattleInterface { BattleUseCaseImpl() }
}
