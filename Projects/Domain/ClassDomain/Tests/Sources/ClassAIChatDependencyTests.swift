//
//  ClassAIChatDependencyTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

import ClassDomain
import ClassDomainInterface
import ComposableArchitecture
import Testing

struct ClassAIChatDependencyTests {
  @Test
  func live_컨텍스트는_실제_대화_UseCase를_등록한다() {
    let isLive = withDependencies {
      $0.context = .live
    } operation: {
      @Dependency(\.classAIChatUseCase) var useCase
      return useCase is ClassAIChatUseCaseImpl
    }

    #expect(isLive)
  }
}
