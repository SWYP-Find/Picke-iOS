import Foundation

public enum ClassError: Error, Equatable, Sendable {
  case invalidCode
  case closed
  case alreadyJoined
  case network(String)
  case unknown(String)

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
