//
//  ClassTicketRegisterNotice.swift
//  Class
//
//  Created by Picke on 11/4/26.
//

import ClassDomainInterface
import PickeSharedUI

/// 이용권 등록 화면 안내(Android `TicketRegisterDialog`).
public enum ClassTicketRegisterNotice: Equatable, Sendable {
  /// 다른 계정에 등록된 코드. 뒤로가기로 화면을 닫는다.
  case alreadyRegistered
  case invalidCode
  case registrationExpired
  case alreadyActive
  case registerFailed

  /// Android `toRegisterDialog`와 같은 매핑. 사용 중 이용권(`TICKET_409_ACTIVE`)만 iOS에서 따로 안내한다.
  public init(error: ClassTicketError) {
    switch error {
    case .claimed: self = .alreadyRegistered
    case .invalidCode, .revoked: self = .invalidCode
    case .registrationExpired: self = .registrationExpired
    case .activeTicket: self = .alreadyActive
    case .notFound, .invalidResponse, .network: self = .registerFailed
    }
  }

  public var alert: CustomAlertState<CustomAlertAction> {
    switch self {
    case .alreadyRegistered: return .ticketAlreadyRegistered()
    case .invalidCode: return .ticketInvalidCode()
    case .registrationExpired: return .ticketRegistrationExpired()
    case .alreadyActive: return .ticketAlreadyActive()
    case .registerFailed: return .ticketRegisterFailed()
    }
  }
}
