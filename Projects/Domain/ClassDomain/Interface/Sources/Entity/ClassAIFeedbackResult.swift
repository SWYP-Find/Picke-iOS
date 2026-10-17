//
//  ClassAIFeedbackResult.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

public enum ClassAIFeedbackResult: Equatable, Sendable {
  case personal(ClassAIPersonalFeedback)
  case classInsight(String)
}
