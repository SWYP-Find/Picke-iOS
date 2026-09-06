//
//  ProfileLiveDependencies.swift
//  ProfileDomain
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import ProfileDomainInterface
import ComposableArchitecture

extension ProfileUseCaseDependency: DependencyKey {
  public static var liveValue: ProfileInterface { ProfileUseCaseImpl() }
}

extension ProfileRepositoryDependency: DependencyKey {
  public static var liveValue: ProfileInterface { ProfileRepositoryImpl() }
}
