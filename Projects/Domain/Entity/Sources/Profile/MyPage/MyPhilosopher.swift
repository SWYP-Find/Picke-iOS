//
//  MyPhilosopher.swift
//  Entity
//

import Foundation

public struct MyPhilosopher: Equatable {
  /// 철학자 유형 코드 (예: `SOCRATES`).
  public let philosopherType: String
  public let philosopherLabel: String
  /// 유형명 (예: `??형`).
  public let typeName: String
  public let description: String
  public let imageURL: String

  public init(
    philosopherType: String,
    philosopherLabel: String,
    typeName: String,
    description: String,
    imageURL: String
  ) {
    self.philosopherType = philosopherType
    self.philosopherLabel = philosopherLabel
    self.typeName = typeName
    self.description = description
    self.imageURL = imageURL
  }

  public static let empty = MyPhilosopher(
    philosopherType: "",
    philosopherLabel: "",
    typeName: "",
    description: "",
    imageURL: ""
  )
}
