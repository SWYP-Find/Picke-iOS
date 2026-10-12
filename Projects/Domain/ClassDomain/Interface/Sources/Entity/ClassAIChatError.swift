//
//  ClassAIChatError.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum ClassAIChatError: Error, Equatable, LocalizedError {
  case unavailable
  case deviceNotEligible
  case appleIntelligenceNotEnabled
  case modelNotReady
  case unsupportedLanguage
  case noSession
  case alreadyResponding
  case contentRejected
  case contextExhausted
  case invalidOutput
  case emptyResponse
  case temporarilyUnavailable
  case unexpectedFailure

  public var requiresChangedInput: Bool {
    self == .contentRejected
  }

  public var canRetryOpening: Bool {
    switch self {
    case .appleIntelligenceNotEnabled, .modelNotReady, .emptyResponse, .temporarilyUnavailable:
      return true
    default:
      return false
    }
  }

  public var isTerminal: Bool {
    switch self {
    case .unavailable, .deviceNotEligible, .unsupportedLanguage, .noSession,
         .contextExhausted, .invalidOutput, .unexpectedFailure:
      return true
    default:
      return false
    }
  }

  public var errorDescription: String? {
    switch self {
    case .unavailable:
      return "이 기기에서는 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .deviceNotEligible:
      return "이 기기는 Apple Intelligence를 지원하지 않아 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .appleIntelligenceNotEnabled:
      return "Apple Intelligence가 꺼져 있어요. 기기 설정에서 켠 뒤 다시 시도해 주세요."
    case .modelNotReady:
      return "AI 모델이 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요."
    case .unsupportedLanguage:
      return "이 기기에서는 한국어 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .noSession:
      return "AI 토론을 시작하지 못했어요. 최종투표로 계속해 주세요."
    case .alreadyResponding:
      return "이전 답변을 기다리고 있어요."
    case .contentRejected:
      return "이 내용에는 답할 수 없어요. 표현을 바꿔 다시 보내 주세요."
    case .contextExhausted:
      return "대화가 길어져 AI 토론을 계속할 수 없어요. 최종투표로 계속해 주세요."
    case .invalidOutput:
      return "AI 응답을 처리할 수 없어요. 최종투표로 계속해 주세요."
    case .emptyResponse:
      return "AI 답변이 비어 있어요. 다시 시도해 주세요."
    case .temporarilyUnavailable:
      return "AI가 잠시 응답하지 못했어요. 잠시 후 다시 시도해 주세요."
    case .unexpectedFailure:
      return "AI 토론을 계속할 수 없어요. 최종투표로 계속해 주세요."
    }
  }
}
