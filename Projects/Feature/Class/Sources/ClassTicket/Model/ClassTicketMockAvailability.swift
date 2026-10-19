import ComposableArchitecture
import Foundation

public enum ClassTicketMockAvailability: DependencyKey {
  #if DEBUG
    public static let liveValue = ProcessInfo.processInfo.environment["PICKE_CLASS_TICKET_MOCK"] == "1"
  #else
    public static let liveValue = false
  #endif

  public static let testValue = false
}

public extension DependencyValues {
  var classTicketMockEnabled: Bool {
    get { self[ClassTicketMockAvailability.self] }
    set { self[ClassTicketMockAvailability.self] = newValue }
  }
}
