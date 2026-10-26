//
//  ClassRepositoryImpl.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import APIEndpoint
import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public final class ClassRepositoryImpl: ClassInterface {
  @Dependency(\.networkClient) var client

  public init() {}

}
