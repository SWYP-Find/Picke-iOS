//
//  NewBattle.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "새로운 배틀" 리스트 아이템 (각 카드에 두 명의 발화자 아바타 포함).
public struct NewBattle: Equatable, Identifiable {
  public let id: UUID
  public let tag: String
  public let durationMinutes: Int
  public let viewCount: Int
  public let title: String
  public let subtitle: String
  public let avatarLabelA: String
  public let avatarSubA: String
  public let avatarLabelB: String
  public let avatarSubB: String

  public init(
    id: UUID = UUID(),
    tag: String,
    durationMinutes: Int,
    viewCount: Int,
    title: String,
    subtitle: String,
    avatarLabelA: String,
    avatarSubA: String,
    avatarLabelB: String,
    avatarSubB: String
  ) {
    self.id = id
    self.tag = tag
    self.durationMinutes = durationMinutes
    self.viewCount = viewCount
    self.title = title
    self.subtitle = subtitle
    self.avatarLabelA = avatarLabelA
    self.avatarSubA = avatarSubA
    self.avatarLabelB = avatarLabelB
    self.avatarSubB = avatarSubB
  }
}

public extension NewBattle {
  static let mocks: [NewBattle] = [
    .init(
      tag: "#철학", durationMinutes: 5, viewCount: 726,
      title: "인간은 본래 선한가, 악한가?",
      subtitle: "인간 본성의 선악과 문명의 역할에 관한 철학적 대결!",
      avatarLabelA: "악하다", avatarSubA: "순자",
      avatarLabelB: "악하다", avatarSubB: "순자"
    ),
    .init(
      tag: "#사회", durationMinutes: 5, viewCount: 726,
      title: "노키즈존: 영업상의 자유인가, 공공장소에서의 차별인가?",
      subtitle: "옆 테이블 아이의 울음소리가 평화로운 휴식시간을 깨뜨린다면?",
      avatarLabelA: "악하다", avatarSubA: "순자",
      avatarLabelB: "악하다", avatarSubB: "순자"
    ),
    .init(
      tag: "#철학", durationMinutes: 5, viewCount: 726,
      title: "사후세계는 존재하는가, 인간이 만든 위안인가?",
      subtitle: "죽음은 끝일까요, 아니면 다른 방식의 시작일까요?",
      avatarLabelA: "악하다", avatarSubA: "순자",
      avatarLabelB: "악하다", avatarSubB: "순자"
    ),
  ]
}
