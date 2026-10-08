import Foundation

public enum ClassAIChatError: Error, Equatable, LocalizedError {
  case unavailable
  case unsupportedLanguage
  case noSession
  case alreadyResponding

  public var errorDescription: String? {
    switch self {
    case .unavailable:
      "이 기기에서는 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .unsupportedLanguage:
      "이 기기에서는 한국어 AI 토론을 사용할 수 없어요. 최종투표로 계속해 주세요."
    case .noSession:
      "AI 토론을 시작하지 못했어요. 최종투표로 계속해 주세요."
    case .alreadyResponding:
      "이전 답변을 기다리고 있어요."
    }
  }
}
