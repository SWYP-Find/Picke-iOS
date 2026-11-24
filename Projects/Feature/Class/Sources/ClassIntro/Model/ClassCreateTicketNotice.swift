//
//  ClassCreateTicketNotice.swift
//  Class
//
//  Created by Picke on 11/4/26.
//

import PickeSharedUI

/// 클래스 만들기 전 이용권 확인 결과로 띄우는 안내(Android `ClassTicketDialog`).
public enum ClassCreateTicketNotice: Equatable, Sendable {
  /// 등록된 이용권이 없음(`TICKET_404`). 닫기만 한다.
  case required
  /// 사용 중이던 이용권이 만료됨. 등록하기로 이용권 등록 화면에 간다.
  case expired

  public var alert: CustomAlertState<CustomAlertAction> {
    switch self {
    case .required: return .classTicketRequired()
    case .expired: return .classTicketExpired()
    }
  }
}
