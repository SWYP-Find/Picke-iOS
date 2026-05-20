//
//  ChatMessage.swift
//  Entity
//
//  채팅방(`/Users/suhwonji/Desktop/와이어프레임/채팅방.pdf` + .pen `k3lIx`) 메시지 모델.
//

import Foundation

public enum ChatSpeakerSide: Equatable, Hashable {
  case left
  case right
}

public struct ChatSpeaker: Equatable, Identifiable, Hashable {
  public let philosopher: PhilosopherAvatar
  public let side: ChatSpeakerSide

  public var id: PhilosopherAvatar { philosopher }

  public init(philosopher: PhilosopherAvatar, side: ChatSpeakerSide) {
    self.philosopher = philosopher
    self.side = side
  }
}

public struct ChatMessage: Equatable, Identifiable, Hashable {
  public let messageId: UUID
  public let speaker: ChatSpeaker
  public let text: String

  public var id: UUID { messageId }

  public init(
    messageId: UUID = UUID(),
    speaker: ChatSpeaker,
    text: String
  ) {
    self.messageId = messageId
    self.speaker = speaker
    self.text = text
  }
}

public struct ChatRoomBundle: Equatable {
  public let battleTitle: String
  public let totalDuration: TimeInterval
  public let leftSpeaker: ChatSpeaker
  public let rightSpeaker: ChatSpeaker
  public let messages: [ChatMessage]

  public init(
    battleTitle: String,
    totalDuration: TimeInterval,
    leftSpeaker: ChatSpeaker,
    rightSpeaker: ChatSpeaker,
    messages: [ChatMessage]
  ) {
    self.battleTitle = battleTitle
    self.totalDuration = totalDuration
    self.leftSpeaker = leftSpeaker
    self.rightSpeaker = rightSpeaker
    self.messages = messages
  }
}

public extension ChatRoomBundle {
  static let mock: ChatRoomBundle = {
    let plato = ChatSpeaker(philosopher: .plato, side: .left)
    let sartre = ChatSpeaker(philosopher: .sartre, side: .right)
    return ChatRoomBundle(
      battleTitle: "뒤샹의 변기, 예술인가 도발인가",
      totalDuration: 268,
      leftSpeaker: plato,
      rightSpeaker: sartre,
      messages: [
        ChatMessage(speaker: plato, text: "이건 기만입니다. 하늘 아래 모든 사물은 그에 걸맞은 완벽한 목적과 형상, 즉 '이데아'를 가지고 있습니다."),
        ChatMessage(speaker: plato, text: "변기의 이데아는 '배설물을 처리하는 것'이지, 감상하는 것이 아닙니다."),
        ChatMessage(speaker: plato, text: "사물의 본질을 왜곡하여 대중을 혼란에 빠뜨리는 것은 진리를 모독하는 행위입니다."),
        ChatMessage(speaker: sartre, text: "플라톤 선생님, 당신은 사물에 '영혼'이 미리 정해져 있다고 믿는군요. 하지만 사물은 그저 그곳에 존재할 뿐입니다."),
        ChatMessage(speaker: sartre, text: "인간이 그것을 어떻게 사용하고 어떤 의미를 부여하느냐에 따라 본질은 언제든 바뀔 수 있습니다."),
        ChatMessage(
          speaker: sartre,
          text: "뒤샹이 이 물건을 '샘'이라고 부르기로 선택한 순간, 이 물체의 본질은 배설 도구에서 예술 작품으로 재탄생한 것입니다. 실존은 본질에 앞서니까요."
        ),
        ChatMessage(speaker: plato, text: "예술이란 이데아를 모방하려는 숭고한 노력입니다. 화가는 붓질을 통해, 조각가는 망치질을 통해 그 본질에 가까워지려 애쓰죠."),
      ]
    )
  }()
}
