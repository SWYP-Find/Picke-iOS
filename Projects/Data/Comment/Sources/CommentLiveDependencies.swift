//
//  CommentLiveDependencies.swift
//  CommentData
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import CommentDomainInterface
import ComposableArchitecture

extension CommentRepositoryDependency: DependencyKey {
  public static var liveValue: CommentInterface { CommentRepositoryImpl() }
}
