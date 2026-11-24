//
//  ClassPerspectiveMenuKind.swift
//  Class
//
//  Created by Picke on 11/3/26.
//

import ClassDomainInterface

/// 클래스 의견 카드 더보기(•••) 메뉴 종류. Android `PerspectiveItemCard.perspectiveMenuItems`와 같다.
public enum ClassPerspectiveMenuKind: Equatable, Sendable {
  case hidden
  case report
  case editOnly
  case editAndDelete

  /// 목록 행: 서버가 남의 의견(false)이라고 알려 준 경우만 신고, 내 의견(true)은 상태 규칙, 모르면(nil) 메뉴 없음.
  public init(listItem: ClassPerspectiveItem) {
    switch listItem.isMyPerspective {
    case .some(false): self = .report
    case .some(true): self = .init(myStatus: listItem.status)
    case .none: self = .hidden
    }
  }

  /// 내 의견: 검수 중은 메뉴 없음, 거절은 수정만, 그 외는 삭제·수정.
  public init(myStatus status: String?) {
    switch status?.uppercased() {
    case "PENDING": self = .hidden
    case "REJECTED": self = .editOnly
    default: self = .editAndDelete
    }
  }

  public var hasMenu: Bool {
    self != .hidden
  }
}
