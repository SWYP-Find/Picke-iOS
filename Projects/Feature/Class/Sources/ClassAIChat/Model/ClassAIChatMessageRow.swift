//
//  ClassAIChatMessageRow.swift
//  Class
//
//  Created by Picke on 11/23/26.
//

import ClassDomainInterface
import Foundation

/// 대화 목록 한 줄. 앞 메시지와 화자가 바뀌는지를 미리 계산해 View가 인덱스를 다루지 않게 한다.
public struct ClassAIChatMessageRow: Equatable, Identifiable {
  public let message: ClassAIChatMessage
  /// 화자가 바뀌어 이름·아바타를 새로 보여줘야 하는 줄인지.
  public let beginsTurn: Bool
  /// 첫 줄이 아니면서 화자가 바뀌는 줄이면 위에 간격을 둔다.
  public let hasTurnSpacing: Bool

  public var id: UUID { message.id }
}
