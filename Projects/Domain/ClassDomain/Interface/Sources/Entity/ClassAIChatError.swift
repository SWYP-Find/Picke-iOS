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

  public var errorDescription: String? {
    switch self {
    case .unavailable:
      "이 기기에서는 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .deviceNotEligible:
      "이 기기는 Apple Intelligence를 지원하지 않아 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .appleIntelligenceNotEnabled:
      "Apple Intelligence가 꺼져 있어요. 기기 설정에서 켠 뒤 다시 시도해 주세요."
    case .modelNotReady:
      "AI 모델이 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요."
    case .unsupportedLanguage:
      "이 기기에서는 한국어 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .noSession:
      "AI 토론을 시작하지 못했어요. 최종투표로 계속해 주세요."
    case .alreadyResponding:
      "이전 답변을 기다리고 있어요."
    }
  }
}
