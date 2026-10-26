import Foundation

public enum ClassBattleError: LocalizedError, Equatable, Sendable {
  case classNotFound
  case membershipRequired
  case ticketEnded
  case closed
  case preVoteLocked
  case invalidOption
  case ttsUnavailable
  case voteNotFound
  case preVoteRequired
  case alreadySubmitted
  case debateIncomplete
  case network(String)
  case invalidResponse

  public var errorDescription: String? { message }

  public var message: String {
    switch self {
    case .classNotFound: return "클래스를 찾을 수 없어요."
    case .membershipRequired: return "이 클래스에 참여 중인 멤버만 이용할 수 있어요."
    case .ticketEnded: return "이용권 기간이 종료됐어요."
    case .closed: return "클래스 참여 기간이 종료됐어요."
    case .preVoteLocked: return "청취 또는 토론을 시작한 뒤에는 사전투표를 바꿀 수 없어요."
    case .invalidOption: return "이 배틀의 선택지가 아니에요."
    case .ttsUnavailable: return "이 클래스에서는 TTS 청취를 사용할 수 없어요."
    case .voteNotFound: return "투표 내역을 찾을 수 없어요."
    case .preVoteRequired: return "먼저 사전투표를 완료해 주세요."
    case .alreadySubmitted: return "사후투표는 다시 제출할 수 없어요."
    case .debateIncomplete: return "AI 토론을 완료한 뒤 투표해 주세요."
    case .network(let message): return message
    case .invalidResponse: return "클래스 배틀 정보를 읽지 못했어요."
    }
  }
}
