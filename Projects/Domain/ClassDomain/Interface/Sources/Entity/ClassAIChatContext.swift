//
//  ClassAIChatContext.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public struct ClassAIChatContext: Equatable, Sendable {
  public let question: String
  public let selectedStance: String
  public let opponentStance: String
  public let opponentPhilosopherName: String?

  public init(
    question: String,
    selectedStance: String,
    opponentStance: String,
    opponentPhilosopherName: String?
  ) {
    self.question = question
    self.selectedStance = selectedStance
    self.opponentStance = opponentStance
    self.opponentPhilosopherName = opponentPhilosopherName
  }
}
