//
//  ClassInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture

public protocol ClassInterface:
  ClassRoomInterface,
  ClassRecommendationInterface,
  ClassBattleInterface,
  ClassMemberInterface,
  ClassDebateInterface,
  ClassTicketInterface,
  ClassResultInterface,
  ClassTopicDraftInterface,
  ClassReportInterface,
  ClassLocalAIInterface {}

public enum ClassRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassMockRepositoryDependency: TestDependencyKey {
  public static var testValue: MockClassRepository? {
    nil
  }
}

public extension DependencyValues {
  var classRepository: any ClassInterface {
    get { self[ClassRepositoryDependency.self] }
    set { self[ClassRepositoryDependency.self] = newValue }
  }

  var classUseCase: any ClassInterface {
    get { self[ClassUseCaseDependency.self] }
    set { self[ClassUseCaseDependency.self] = newValue }
  }

  var classMockRepository: MockClassRepository? {
    get { self[ClassMockRepositoryDependency.self] }
    set { self[ClassMockRepositoryDependency.self] = newValue }
  }
}
