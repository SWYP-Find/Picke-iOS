//
//  SearchLiveDependencies.swift
//  SearchDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import SearchDomainInterface
import ComposableArchitecture

extension SearchUseCaseDependency: DependencyKey {
  public static var liveValue: SearchInterface { SearchUseCaseImpl() }
}
