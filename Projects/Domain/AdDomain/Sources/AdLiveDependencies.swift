//
//  AdLiveDependencies.swift
//  AdDomain
//
//  Created by Picke on 10/11/26.
//

import AdDomainInterface
import ComposableArchitecture

extension FeedAdUseCaseDependency: DependencyKey {
  public static var liveValue: FeedAdInterface { FeedAdUseCaseImpl() }
}

extension FeedAdRepositoryDependency: DependencyKey {
  public static var liveValue: FeedAdInterface { FeedAdRepositoryImpl() }
}
