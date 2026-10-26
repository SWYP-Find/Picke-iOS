//
//  ClassUseCaseImpl.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassUseCaseImpl: ClassInterface {
  @Dependency(\.classRepository) var repository

  public init() {}

}
