//
//  ClassAIFeedbackError.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

import Foundation

public enum ClassAIFeedbackError: Error, Equatable, Sendable {
  case deviceNotEligible
  case appleIntelligenceNotEnabled
  case unsupportedLanguage
  case modelNotReady
  case temporarilyUnavailable
  case insufficientInput
  case contextTooLong
  case generationFailed
  case serverRetryAvailable

  public var isUnavailable: Bool {
    switch self {
    case .deviceNotEligible, .appleIntelligenceNotEnabled, .unsupportedLanguage: return true
    default: return false
    }
  }

  public var isRetryable: Bool {
    switch self {
    case .modelNotReady, .temporarilyUnavailable, .serverRetryAvailable: return true
    default: return false
    }
  }
}
