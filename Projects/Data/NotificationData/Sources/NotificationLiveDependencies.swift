//
//  NotificationLiveDependencies.swift
//  NotificationData
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import NotificationDomainInterface
import ComposableArchitecture

extension NotificationRepositoryDependency: DependencyKey {
  public static var liveValue: NotificationInterface { NotificationRepositoryImpl() }
}
