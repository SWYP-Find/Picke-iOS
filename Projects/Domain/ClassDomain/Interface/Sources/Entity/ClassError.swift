import Foundation

public enum ClassError: LocalizedError, Equatable, Sendable {
  case invalidCode
  case closed
  case alreadyJoined
  case network(String)
  case unknown(String)

  public var errorDescription: String? {
    message
  }

  public var message: String {
    switch self {
    case .invalidCode: "참여 코드를 다시 확인해 주세요."
    case .closed: "종료된 클래스입니다."
    case .alreadyJoined: "이미 참여한 클래스입니다."
    case let .network(message), let .unknown(message): message
    }
  }

  public static func from(_ error: Error) -> ClassError {
    if let error = error as? ClassError {
      return error
    }
    if let error = error as? URLError {
      return .network(error.localizedDescription)
    }
    return .unknown(String(describing: error))
  }
}
