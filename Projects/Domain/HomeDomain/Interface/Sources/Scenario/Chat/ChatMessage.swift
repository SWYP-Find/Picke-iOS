//
//  ChatMessage.swift
//  Entity
//

import Foundation

public struct ChatMessage: Equatable, Identifiable, Hashable {
  public let messageId: UUID
  public let speaker: ChatSpeaker
  public let text: String
  /// 시나리오 스크립트의 시작 시각 (밀리초). 오디오 재생 진행도에 따라
  public let startTimeMs: Int?

  public var id: UUID { messageId }

  public init(
    messageId: UUID = UUID(),
    speaker: ChatSpeaker,
    text: String,
    startTimeMs: Int? = nil
  ) {
    self.messageId = messageId
    self.speaker = speaker
    self.text = text
    self.startTimeMs = startTimeMs
  }
}
