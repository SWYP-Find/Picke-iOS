import Foundation

public struct NetworkTelemetryEvent: Sendable {
  public let source: String
  public let method: String
  public let host: String
  public let path: String
  public let statusCode: Int?
  public let durationMilliseconds: Int
  public let isSuccess: Bool

  public init(
    source: String,
    method: String,
    url: URL?,
    statusCode: Int?,
    duration: TimeInterval,
    isSuccess: Bool
  ) {
    self.source = source
    self.method = method
    host = url?.host ?? ""
    path = url?.path ?? ""
    self.statusCode = statusCode
    durationMilliseconds = max(0, Int(duration * 1000))
    self.isSuccess = isSuccess
  }
}

public final class NetworkTelemetry: @unchecked Sendable {
  public static let shared = NetworkTelemetry()

  private let lock = NSLock()
  private var handler: (@Sendable (NetworkTelemetryEvent) -> Void)?

  private init() {}

  public func configure(
    handler: @escaping @Sendable (NetworkTelemetryEvent) -> Void
  ) {
    lock.withLock {
      self.handler = handler
    }
  }

  public func record(_ event: NetworkTelemetryEvent) {
    let currentHandler = lock.withLock { handler }
    currentHandler?(event)
  }
}
