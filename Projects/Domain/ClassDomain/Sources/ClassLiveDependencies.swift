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

extension ClassRepositoryDependency: DependencyKey {
  public static var liveValue: any ClassInterface {
    ClassLiveRepository(api: ClassRepositoryImpl())
  }
}
