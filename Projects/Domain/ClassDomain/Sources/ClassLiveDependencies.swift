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
    ClassLiveRepository(
      mock: ClassMockRepositoryStorage.shared,
      recommendations: ClassRepositoryImpl()
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
