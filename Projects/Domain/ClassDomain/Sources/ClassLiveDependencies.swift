//
//  ClassLiveDependencies.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture

extension ClassUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassUseCaseImpl()
  }
}

extension ClassBattleUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassBattleInterface {
    ClassBattleUseCaseImpl()
  }
}

extension ClassBattleRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassBattleInterface {
    ClassBattleRepositoryImpl()
  }
}

extension ClassMemberUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassMemberInterface {
    ClassMemberUseCaseImpl()
  }
}

extension ClassMemberRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassMemberInterface {
    ClassMemberRepositoryImpl()
  }
}

extension ClassAIChatUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassAIChatInterface {
    ClassAIChatUseCaseImpl()
  }
}

extension ClassAIFeedbackUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassAIFeedbackInterface {
    ClassAIFeedbackUseCaseImpl()
  }
}

extension ClassResultUseCaseDependency: DependencyKey {
  public static var liveValue: any ClassResultInterface { ClassResultUseCaseImpl() }
}

extension ClassResultRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassResultInterface { ClassResultRepositoryImpl() }
}

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassLiveRepository(
      mock: ClassMockRepositoryStorage.shared,
      api: ClassRepositoryImpl()
    )
  }
}

extension ClassMockRepositoryDependency: DependencyKey {
  public static var liveValue: MockClassRepository? {
    ClassMockRepositoryStorage.shared
  }
}

private enum ClassMockRepositoryStorage {
  static let shared = MockClassRepository()
}
