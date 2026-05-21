//
//  AudioPlayerInterface.swift
//  DomainInterface
//
//  채팅방 / 배틀 상세 등 한 번에 하나의 음원만 재생되는 환경을 위한 단일 플레이어 인터페이스.
//

import Dependencies
import Foundation
import WeaveDI

public protocol AudioPlayerInterface: Sendable {
  func load(url: URL) async
  func play() async
  func pause() async
  func seek(to time: TimeInterval) async
  func duration() async -> TimeInterval
  func currentTimes() -> AsyncStream<TimeInterval>
}

public struct DefaultAudioPlayerImpl: AudioPlayerInterface {
  public init() {}
  public func load(url _: URL) async {}
  public func play() async {}
  public func pause() async {}
  public func seek(to _: TimeInterval) async {}
  public func duration() async -> TimeInterval { 0 }
  public func currentTimes() -> AsyncStream<TimeInterval> { AsyncStream { _ in } }
}

public struct AudioPlayerDependency: DependencyKey {
  public static var liveValue: AudioPlayerInterface {
    UnifiedDI.resolve(AudioPlayerInterface.self) ?? DefaultAudioPlayerImpl()
  }

  public static var testValue: AudioPlayerInterface {
    UnifiedDI.resolve(AudioPlayerInterface.self) ?? DefaultAudioPlayerImpl()
  }

  public static var previewValue: AudioPlayerInterface = liveValue
}

public extension DependencyValues {
  var audioPlayer: AudioPlayerInterface {
    get { self[AudioPlayerDependency.self] }
    set { self[AudioPlayerDependency.self] = newValue }
  }
}
