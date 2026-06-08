//
//  ChatMessage.swift
//  Entity
//
//  채팅방(`/Users/suhwonji/Desktop/와이어프레임/채팅방.pdf` + .pen `k3lIx`) 메시지 모델.
//

import Foundation

public struct ChatMessage: Equatable, Identifiable, Hashable {
  public let messageId: UUID
  public let speaker: ChatSpeaker
  public let text: String
  /// 시나리오 스크립트의 시작 시각 (밀리초). 오디오 재생 진행도에 따라
  /// 활성 메시지로 자동 스크롤할 때 사용. mock 데이터 / 시간 정보가 없는
  /// 경우엔 nil.
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
