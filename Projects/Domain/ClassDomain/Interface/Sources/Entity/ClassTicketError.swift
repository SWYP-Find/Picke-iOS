import Foundation

public enum ClassTicketError: LocalizedError, Equatable, Sendable {
  case invalidCode
  case revoked
  case registrationExpired
  case claimed
  case activeTicket
  case notFound
  case invalidResponse
  case network(String)

  public var errorDescription: String? { message }

  public var message: String {
    switch self {
    case .invalidCode: return "유효하지 않은 이용권 코드예요. 다시 확인해 주세요."
    case .revoked: return "재발급되거나 취소된 이용권 코드예요."
    case .registrationExpired: return "등록 기한이 지난 이용권 코드예요."
    case .claimed: return "이미 다른 계정에 등록된 이용권 코드예요."
    case .activeTicket: return "이미 사용 중인 이용권이 있어요. 만료 후 등록할 수 있어요."
    case .notFound: return "등록된 이용권이 없어요."
    case .invalidResponse: return "이용권 정보를 읽지 못했어요. 다시 시도해 주세요."
    case let .network(message): return message
    }
  }
}
